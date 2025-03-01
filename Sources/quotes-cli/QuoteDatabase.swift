import Foundation
import SQLite3

class QuoteDatabase {
    private var db: OpaquePointer?

    init() {
        do {
            // Locate the quotes.db file in the current directory
            let path = FileManager.default.currentDirectoryPath + "/quotes.db"
            if sqlite3_open(path, &db) != SQLITE_OK {
                fatalError("Unable to open database")
            }
            createTable()
        } catch {
            fatalError("Unable to initialize database: \(error)")
        }

    func createTable() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
        );
        """
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Quotes table created.")
            } else {
                print("Quotes table could not be created.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared.")
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
                print("Successfully inserted quote.")
            } else {
                print("Could not insert quote.")
            }
        } else {
            print("INSERT statement could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
        }
    }
}
