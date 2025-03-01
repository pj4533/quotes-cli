import Foundation
import SQLite

class QuoteDatabase {
    private var db: Connection
    private let quotesTable = Table("quotes")
    private let id = Expression<Int64>(value: "id")
    private let quote = Expression<String>(value: "quote")
    private let createdAt = Expression<String>(value: "created_at") // Changed to String to handle Date serialization

    init() {
        do {
            // Locate the quotes.db file in the current directory
            let path = FileManager.default.currentDirectoryPath + "/quotes.db"
            db = try Connection(path)
            try createTable()
        } catch {
            fatalError("Unable to initialize database: \(error)")
        }
    }

    func createTable() throws {
        do {
            try db.run(quotesTable.create(ifNotExists: true) { table in
                table.column(id, primaryKey: true)
                table.column(quote)
                table.column(createdAt, defaultValue: Expression<String>(value: ISO8601DateFormatter().string(from: Date())))
            })
        } catch {
            throw error
        }
    }

    func saveQuote(_ quoteText: String) {
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: Date())
        let insert = quotesTable.insert(
            quote <- quoteText,
            createdAt <- dateString
        )
        do {
            let rowId = try db.run(insert)
            print("Quote saved with ID: \(rowId)")
        } catch {
            print("Failed to save quote: \(error)")
        }
    }
}
