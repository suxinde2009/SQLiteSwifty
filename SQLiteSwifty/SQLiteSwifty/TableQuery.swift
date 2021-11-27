//
//  TableQuery.swift
//  SQLiteSwifty
//
//  Created by SuXinDe on 2021/11/26.
//

import Foundation

extension SQLite {
    
    /// A query interface of table
    public class TableQuery<T: SQLiteCodable> {
        
        private let connection: SQLite.Connection
        private let table: SQLite.TableMapping
        private var _limit: Int?
        private var _offset: Int?
        private var _orderBys: [SQLite.Connection.Ordering]?
        
        init(connection: SQLite.Connection,
             table: SQLite.TableMapping) {
            
            self.connection = connection
            self.table = table
        }
        
        /// Execute SELECT COUNT(*) FROM `Table`
        public var count: Int {
            do {
                let c: Int = try generateCommand("COUNT(*)").executeScalar() ?? 0
                return c
            } catch {
                print(error)
            }
            return 0
        }
        
        private func generateCommand(_ selection: String) -> SQLite.Command {
            var cmdText = "SELECT \(selection) FROM \(table.tableName)"
            
            if let orderBy = _orderBys, orderBy.count > 0 {
                let sql = orderBy.map { return $0.declaration }.joined(separator: ",")
                cmdText += " ORDER BY " + sql
            }
            if let limit = _limit {
                cmdText += " LIMIT \(limit)"
            }
            if let offset = _offset {
                if _limit == nil {
                    cmdText = " LIMIT -1"
                }
                cmdText += " OFFSET \(offset)"
            }
            let args: [Any] = []
            return connection.createCommand(cmdText, parameters: args)
        }
        
        /// Execute SELECT * FROM `Table`
        ///
        /// - Returns: All rows
        public func toList() -> [T] {
            return generateCommand("*").executeQuery()
        }
        
        /// Filter using NSPredicate.
        /// NOTE: Key used in predicate must be one of properties name within your table model.
        ///
        /// - Parameter predicate: predicate
        /// - Returns: All objects that match the predicate
        public func filter<T: SQLiteCodable>(using predicate: NSPredicate) -> [T] {
            let predication = predicate.predicateFormat
            print(predication.description)
            let cmdText = "SELECT * FROM \(table.tableName)"
            let result: [T] = connection.createCommand(cmdText, parameters: []).executeQuery()
            if result.count == 0 {
                return []
            }
            let r = (result as! NSMutableArray).filtered(using: predicate) as! [T]
            return r
        }
        
        
        /// Yields a given number of elements from the query and then skips the remainder.
        ///
        /// - Parameter limit: Limit number that your want to select.
        /// - Returns: SQLiteTableQuery
        public func limit<T: SQLiteCodable>(_ limit: Int) -> TableQuery<T> {
            let q: TableQuery<T> = clone()
            q._limit = limit
            return q
        }
        
        public func `where`(_ condition: String) -> TableQuery<T> {
            let q: TableQuery<T> = clone()
            return q
        }
        
        
        /// Order the query results according to a key.
        ///
        /// - Parameter order: order
        /// - Returns: SQLiteTableQuery
        public func orderBy(_ order: SQLite.Connection.Ordering) -> TableQuery<T> {
            let q: TableQuery<T> = clone()
            return q
        }
        
        public func distinct(_ columns: String...) -> TableQuery<T> {
            let q: TableQuery<T> = clone()
            return q
        }
        
        fileprivate func clone<T: SQLiteCodable>() -> TableQuery<T> {
            let query = TableQuery<T>(connection: connection, table: table)
            query._limit = _limit
            query._offset = _offset
            query._orderBys = _orderBys
            return query
        }
    }
    
}

