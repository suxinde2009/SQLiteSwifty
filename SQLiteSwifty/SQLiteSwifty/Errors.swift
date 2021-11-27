//
//  SQLite.ErrorType.swift
//  SQLiteSwifty
//
//  Created by SuXinDe on 2021/11/26.
//

import Foundation

extension SQLite {
    /// SQLite Errors that maybe throwed by SQLiteSwifty
    ///
    /// - openDataBaseError: Can not open the database file to operate. With Error Message and error.
    /// - executeError: Execute statement occurs exception.
    /// - notNullConstraintViolation: Insert or Update not null column with null value.
    /// - prepareError: Prepare statement error.
    /// - jsonDecoderError: JSONDecoder error. Could not decode data read from database.
    /// - notSupportedError: SQLiteSwifty do not support
    public enum ErrorType: Error {
        case openDataBaseError(String)
        case executeError(Int, String)
        case notNullConstraintViolation(Int, String)
        case prepareError(String)
        case jsonDecoderError(Error)
        case notSupportedError(String)
    }
}
