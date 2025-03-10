import Foundation
import SQLite3
import os

class QuoteDatabase {
    private var db: OpaquePointer?
    private let logger = Logger(subsystem: "com.yourapp.quotes-cli", category: "QuoteDatabase")

    init() {
        // Locate the quotes.db file in the current directory
        let path = FileManager.default.currentDirectoryPath + "/quotes.db"
        if sqlite3_open(path, &db) != SQLITE_OK {
            logger.error("Unable to open database")
            fatalError("Unable to open database")
        }
        createTable()
    }

    func createTable() {
        // Check if the table already exists
        var stmt: OpaquePointer?
        let checkTableString = "SELECT name FROM sqlite_master WHERE type='table' AND name='quotes';"
        
        if sqlite3_prepare_v2(db, checkTableString, -1, &stmt, nil) == SQLITE_OK {
            // If step returns SQLITE_ROW, the table exists
            if sqlite3_step(stmt) == SQLITE_ROW {
                logger.info("Quotes table already exists, skipping creation")
                sqlite3_finalize(stmt)
                return
            }
            sqlite3_finalize(stmt)
        }
        
        // Table doesn't exist, create it
        let createTableString = """
        CREATE TABLE IF NOT EXISTS quotes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            quote TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        );
        """
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                logger.error("Quotes table could not be created. Error: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            logger.error("CREATE TABLE statement could not be prepared. Error: \(errorMessage)")
        }
        sqlite3_finalize(createTableStatement)
    }

    func saveQuote(_ quoteText: String) {
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: Date())
        var insertStatement: OpaquePointer?
        let insertStatementString = "INSERT INTO quotes (quote, created_at) VALUES (?, ?);"
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, (quoteText as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (dateString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                // Successfully inserted quote.
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                logger.error("Could not insert quote. Error: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            logger.error("INSERT statement could not be prepared. Error: \(errorMessage)")
        }
        sqlite3_finalize(insertStatement)
    }
}
