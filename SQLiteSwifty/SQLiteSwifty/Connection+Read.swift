//
//  SQLiteConnection+Read.swift
//  SQLiteSwifty
//
//  Created by SuXinDe on 2021/11/26.
//

import Foundation

extension SQLite.Connection {
    
    /// Updates all of the columns of a table using the specified object
    /// except for its primary key.
    /// The object is required to have a primary key.
    ///
    /// - Parameter obj: The object to update. It must have a primary key designated using the Attribute.isPK.
    /// - Returns: The number of rows updated.
    /// - Throws: Exceptions
    @discardableResult
    public func update<Object: SQLiteCodable>(_ obj: Object) throws -> Int {
        let map = getMapping(of: Object.self)
        guard let pk = map.pk else {
            throw SQLite.ErrorType.notSupportedError("Could not update table without primary key")
        }
        let cols = map.columns.filter { return $0.isPK == false }
        let sets = cols.map { return "\($0.name) = ?" }.joined(separator: ",")
        var values: [Any] = cols.map { return $0.getValue(of: obj) }
        values.append(pk.getValue(of: obj))
        let sql = String(format: "UPDATE %@ SET %@ WHERE %@ = ?", map.tableName, sets, pk.name)
        return try execute(sql, parameters: values)
    }
    
    
    // TODO: Bug needs to be fixed.
    @discardableResult
    public func insertOrUpdate<Object: SQLiteCodable>(_ obj: Object) throws -> Int {
        if SQLite.Connection.libVersionNumber > 3024000 {
            // TODO
//            let result = try insert(obj, extra: "OR IGNORE")
//            if result != SQLite.Result.ok.rawValue {
//                return try update(obj)
//            }
//            return result
        } else {
            // create two statements
            let result = try insert(obj, extra: "OR IGNORE")
            if result != SQLite.Result.ok.rawValue {
                return try update(obj)
            }
            return result
        }
        return Int(SQLite.Result.ok.rawValue)
    }
}
