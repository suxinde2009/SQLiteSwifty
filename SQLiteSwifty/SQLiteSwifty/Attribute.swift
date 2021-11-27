//
//  Attribute.swift
//  SQLiteSwifty
//
//  Created by SuXinDe on 2021/11/26.
//

import Foundation


extension SQLite {
    
    /// Specified column attributes with your codable model
    /// eg: Specifiy `Primary Key` with Attribute.isPK
    /// eg: Specifiy `AUTOINCREMENT Key` with Attribute.autoInc
    public struct AttributeInfo {
        
        /// Name of property
        public let name: String
        
        /// Attribute of property
        public let attribute: Attribute
        
        public init(name: String, attribute: Attribute) {
            self.name = name
            self.attribute = attribute
        }
    }
    
    public struct Attribute: OptionSet {
        
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let none = Attribute(rawValue: 1 << 0)
        
        /// Make property the primary key of table
        public static let isPrimaryKey = Attribute(rawValue: 1 << 1)
        
        /// Make property AUTOINCREMENT
        /// NOTE: Only support `Int` or `Int64`
        public static let autoIncrement = Attribute(rawValue: 1 << 2)
        
        /// Create index
        public static let indexed = Attribute(rawValue: 1 << 4)
        
        /// Table name
        public static let tableName = Attribute(rawValue: 1 << 5)
        
    }
    
    
    /// Select the collating sequence to use on a column. `binary` is the default.
    ///
    /// - binary: The `BINARY` built-in SQL collation
    /// - nocase: The `NOCASE` built-in SQL collation
    /// - rtrim:  The `RTRIM` built-in SQL collation
    public enum CollationName: String {
        case binary = "BINARY"
        case nocase = "NOCASE"
        case rtrim = "RTRIM"
    }
}







