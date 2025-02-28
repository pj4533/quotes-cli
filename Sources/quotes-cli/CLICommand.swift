import ArgumentParser
import DotEnv
import SQLite

struct QuotesCommand: ParsableCommand {
    @Argument(help: "Theme for the quotes")
    var theme: String

    // Initialize QuoteDatabase
    let quoteDatabase = QuoteDatabase()

    func run() {
        DotEnv.load()
        guard let apiKey = DotEnv.env["OPENAI_API_KEY"] else {
            print("Error: OPENAI_API_KEY not set in .env file.")
            exit(1)
        }
        print("Theme received: \(theme)")
        
        let service = OpenAIService()
        let quote = service.fetchQuote(theme: theme)
        print(quote)
        
        // Save the fetched quote to the database
        quoteDatabase.saveQuote(quote)
        
        let inputHandler = UserInputHandler()
        if let result = inputHandler.waitForArrowKey() {
            print("Arrow key pressed: \(result)")
        } else {
            print("No input detected.")
        }
        
        // For confirmation, save a test quote
        quoteDatabase.saveQuote("Test quote")
    }
}
