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
            printTableInfo()
        } catch {
            fatalError("Unable to initialize database: \(error)")
        }
    }

    func createTable() {
        let dropTableString = "DROP TABLE IF EXISTS quotes;"
        if sqlite3_exec(db, dropTableString, nil, nil, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("DROP TABLE statement could not be executed. Error: \(errorMessage)")
        } else {
            print("Existing quotes table dropped.")
        }

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
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("CREATE TABLE statement could not be prepared. Error: \(errorMessage)")
        }
        sqlite3_finalize(createTableStatement)
    }

    func printTableInfo() {
        let tableInfoQuery = "PRAGMA table_info(quotes);"
        var queryStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, tableInfoQuery, -1, &queryStatement, nil) == SQLITE_OK {
            print("Current quotes table schema:")
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let cid = sqlite3_column_int(queryStatement, 0)
                if let nameCStr = sqlite3_column_text(queryStatement, 1) {
                    let name = String(cString: nameCStr)
                    let typeCStr = sqlite3_column_text(queryStatement, 2)
                    let type = typeCStr != nil ? String(cString: typeCStr!) : ""
                    let notnull = sqlite3_column_int(queryStatement, 3)
                    let dfltValueCStr = sqlite3_column_text(queryStatement, 4)
                    let dfltValue = dfltValueCStr != nil ? String(cString: dfltValueCStr!) : "NULL"
                    let pk = sqlite3_column_int(queryStatement, 5)
                    print("cid: \(cid), name: \(name), type: \(type), notnull: \(notnull), dflt_value: \(dfltValue), pk: \(pk)")
                }
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Failed to retrieve table info. Error: \(errorMessage)")
        }
        sqlite3_finalize(queryStatement)
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
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Could not insert quote. Error: \(errorMessage)")
                print("Failed Quote Text: \(quoteText)")
                print("Failed Date String: \(dateString)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("INSERT statement could not be prepared. Error: \(errorMessage)")
            print("Insert Statement: \(insertStatementString)")
            print("Quote Text: \(quoteText)")
            print("Date String: \(dateString)")
        }
        sqlite3_finalize(insertStatement)
    }
}
