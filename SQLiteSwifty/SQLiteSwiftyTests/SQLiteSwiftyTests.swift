//
//  SQLiteSwiftyTests.swift
//  SQLiteSwiftyTests
//
//  Created by SuXinDe on 2021/11/26.
//

import XCTest
@testable import SQLiteSwifty


class User: NSObject, SQLiteCodable {
    
    enum CodingKeys: String,  SQLiteCodingKey {
        typealias root = User
        case userID = "userID"
        case name = "name"
        case age = "age"
        case birthday = "birthday"
        case avatarData = "avatarData"
    }
    
    var userID: Int
    var name: String
    var age: Int
    var birthday: Date
    
    var avatarData: Data?
    
    static func attributes() -> [SQLite.AttributeInfo] {
        return [
            SQLite.AttributeInfo(name: "userID", attribute: .isPrimaryKey),
            SQLite.AttributeInfo(name: "userID", attribute: .autoIncrement)
        ]
    }
    
    required override init() {
        userID = 0
        name = ""
        age = 0
        
        birthday = Date()
    }
    
    override var description: String {
        return "\nuserID: \(userID), name: \(name), age:\(age), birthday:\(birthday)\n"
    }
}

class School: Codable {
    
    public let name: String
    
    public let rank: Int
    
    init(name: String, rank: Int) {
        self.name = name
        self.rank = rank
    }
}


class SQLiteSwiftyTests: XCTestCase {

    var db: SQLite.Connection!
    
    fileprivate func queryUsers() {
        let userQuery: SQLite.TableQuery<User> = db.table()
        let count = userQuery.count
        print("find users count:\(count)")
        var users: [User] = userQuery.limit(count).toList()
        print(users)
        print("\n")
        
        //
        print("Update......\n")
        
        let u = User()
        u.userID = 2
        u.name = "222"
        u.age = 30
        u.birthday = Date()
        
        try! db.insertOrUpdate(u)
        
        users = userQuery.limit(count).toList()
        print(users)
    }
    
    fileprivate func insertUsers() {
        let users = [
            ("A", 11),
            ("B", 12),
            ("C", 13),
            ("D", 14)
        ]
        
        users.forEach { item in
            let user = User()
            user.name = item.0
            user.age = item.1
            user.birthday = Date()
            try! db.insert(user)
        }
        
    }
    
    func testDBCreate() {
        let bundle = Bundle.init(for: SQLiteSwiftyTests.self)
        let dbFile = bundle.bundlePath.appending("/db.sqlite")
        db = try! SQLite.Connection(databasePath: dbFile)
        try! db.createTable(User.self)
        insertUsers()
        queryUsers()
        print("End...")
    }

}
