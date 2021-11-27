//
//  Command.swift
//  SQLiteSwifty
//
//  Created by SuXinDe on 2021/11/26.
//

import Foundation
import CoreGraphics


internal extension SQLite {
    class Command {
        
        struct Binding {
            public let name: String?
            public let value: Any?
            public var index: Int = 0
            
            init(name: String?, value: Any?) {
                self.name = name
                self.value = value
                self.index = 0
            }
        }
        
        fileprivate let conn: Connection
        
        fileprivate var _bindings: [Binding] = []
        
        var commandText: String = ""
        
        init(connection: Connection) {
            conn = connection
        }
        
        func bind(_ name: String?,
                  value: Any?) {
            
            let binding = Binding(name: name, value: value)
            _bindings.append(binding)
        }
        
        func bind(_ value: Any?) {
            bind(nil, value: value)
        }
        
        func bindAll(_ stmt: SQLite.Statement) throws {
            var index = 1
            for var bind in _bindings {
                if let name = bind.name {
                    bind.index = SQLite.bindParameterIndex(stmt, name: name)
                } else {
                    index += 1
                    bind.index = index
                }
                try Command.bindParameter(stmt, index: index, value: bind.value)
            }
        }
        
        @discardableResult
        static func bindParameter(_ stmt: SQLite.Statement,
                                  index: Int,
                                  value: Any?) throws -> Int {
            
            let code: Int
            if let value = value {
                switch value {
                    case let v as String:
                        code = SQLite.bindText(stmt, index: index, value: v)
                    case let v as Bool:
                        code = SQLite.bindInt(stmt, index: index, value: v ? 1 : 0)
                    case let v as Int:
                        code = SQLite.bindInt(stmt, index: index, value: v)
                    case let v as Int32:
                        code = SQLite.bindInt(stmt, index: index, value: Int(v))
                    case let v as Int64:
                        code = SQLite.bindDouble(stmt, index: index, value: Double(v))
                    case let v as Float:
                        code = SQLite.bindDouble(stmt, index: index, value: Double(v))
                    case let v as Double:
                        code = SQLite.bindDouble(stmt, index: index, value: v)
                    case let v as CGFloat:
                        code = SQLite.bindDouble(stmt, index: index, value: Double(v))
                    case let v as Date:
                        let interval = v.timeIntervalSince1970
                        code = SQLite.bindDouble(stmt, index: index, value: interval)
                    case let v as URL:
                        code = SQLite.bindText(stmt, index: index, value: v.absoluteString)
                    case let v as Data:
                        code = SQLite.bindBlob(stmt, index: index, value: v)
                    default:
                        // NOTE: When Any? is Option<Any> = nil, value == nil always retrun false.
                        if value is ExpressibleByNilLiteral {
                            return SQLite.bindNull(stmt, index: index)
                        }
                        throw SQLite.ErrorType.notSupportedError("Unsupported parameter type, value: \(value)")
                }
            } else {
                code = SQLite.bindNull(stmt, index: index)
            }
            return code
        }
        
        
        func readColumn(_ stmt: SQLite.Statement,
                        index: Int,
                        columnType: SQLite.ColumnType,
                        type: Any.Type) -> Any? {
            
            switch columnType {
                case .Text:
                    return SQLite.columnText(stmt, index: index)
                case .Integer:
                    let value = SQLite.columnInt(stmt, index: index)
                    if type is Bool.Type {
                        return value == 1
                    }
                    return value
                case .Float:
                    return SQLite.columnDouble(stmt, index: index)
                case .Blob:
                    return SQLite.columnBlob(stmt, index: index)
                case .Null:
                    return nil
            }
        }
        
        func prepare() throws -> SQLite.Statement {
            guard let stmt = SQLite.prepare(conn.handle, SQL: commandText) else {
                let msg = SQLite.getErrorMessage(conn.handle)
                throw SQLite.ErrorType.prepareError(msg)
            }
            try bindAll(stmt)
            return stmt
        }
        
        func executeScalar<T>() throws -> T? {
            let stmt = try prepare()
            guard let r = SQLite.step(stmt) else {
                return nil
            }
            
            if r == SQLite.Result.row || r == SQLite.Result.done {
                let colType = SQLite.columnType(stmt, index: 0)
                let value = readColumn(stmt, index: 0, columnType: colType, type: T.self) as? T
                SQLite.finalize(stmt)
                return value
            } else {
                let msg = SQLite.getErrorMessage(conn.handle)
                throw SQLite.ErrorType.executeError(Int(r.rawValue), msg)
            }
        }
        
        @discardableResult
        func executeNonQuery() throws -> Int {
            let stmt = try prepare()
            guard let r = SQLite.step(stmt) else {
                return 0
            }
            SQLite.finalize(stmt)
            if r == SQLite.Result.done {
                let rowsAffected = SQLite.changes(conn.handle)
                return rowsAffected
            } else if r == SQLite.Result.error {
                let msg = SQLite.getErrorMessage(conn.handle)
                throw SQLite.ErrorType.executeError(Int(r.rawValue), msg)
            } else if r == SQLite.Result.constraint {
                let msg = SQLite.getErrorMessage(conn.handle)
                throw SQLite.ErrorType.notNullConstraintViolation(Int(r.rawValue), msg)
            }
            throw SQLite.ErrorType.executeError(Int(r.rawValue), "")
        }
        
        func executeQuery<T: SQLiteCodable>() -> [T] {
            let map = conn.getMapping(of: T.self)
            do {
                return try executeDeferredQuery(map)
            } catch {
                print(error)
                return []
            }
        }
        
        func executeDeferredQuery<T: SQLiteCodable>(_ map: TableMapping) throws -> [T] {
            let stmt = try prepare()
            let columnCount = SQLite.columnCount(stmt)
            var cols: [TableMapping.Column?] = []
            for i in 0..<columnCount {
                let name = SQLite.columnName(stmt, index: i)
                let column = map.findColumn(with: name)
                cols.append(column)
            }
            
            var result: [T] = []
            while SQLite.step(stmt) == SQLite.Result.row {
                // currently use JSONSerialization and JSONDecoder to ORM mapping
                var dict: [String: Any?] = [:]
                for i in 0..<columnCount {
                    if let col = cols[i] {
                        let colType = SQLite.columnType(stmt, index: i)
                        let value = readColumn(stmt, index: i, columnType: colType, type: col.columnType)
                        dict[col.name] = value
                    }
                }
                do {
                    let data = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let obj = try JSONDecoder().decode(T.self, from: data)
                    result.append(obj)
                } catch {
                    throw SQLite.ErrorType.jsonDecoderError(error)
                }
            }
            SQLite.finalize(stmt)
            return result
        }
    }
    
    class PreparedSqliteInsertCommand {
        
        private let conn: Connection
        
        private let commandText: String
        
        private var statement: SQLite.Statement?
        
        init(connection: Connection, commandText: String) {
            self.conn = connection
            self.commandText = commandText
        }
        
        deinit {
            if let stmt = statement {
                SQLite.finalize(stmt)
            }
        }
        
        func executeNonQuery(_ args: [Any]) throws -> Int {
            guard let stmt = SQLite.prepare(conn.handle, SQL: commandText) else {
                return 0
            }
            for (index, arg) in args.enumerated() {
                try Command.bindParameter(stmt, index: index + 1, value: arg)
            }
            let r = SQLite.step(stmt)
            if r == SQLite.Result.done {
                let rows = SQLite.changes(conn.handle)
                return rows
            }
            return 0
        }
        
    }
    
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()
