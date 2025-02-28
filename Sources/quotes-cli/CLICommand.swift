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
        let inputHandler = UserInputHandler()
        
        while true {
            let quote = service.fetchQuote(theme: theme)
            print("\nQuote: \(quote)\n")
            
            let result = inputHandler.waitForArrowKey()
            
            switch result {
            case "LEFT":
                print("Discarded. Fetching new quote...")
                continue
            case "RIGHT":
                quoteDatabase.saveQuote(quote)
                print("Quote saved!")
            case "EXIT":
                print("\nGoodbye!")
                exit(0)
            default:
                print("No valid input detected. Fetching new quote...")
                continue
            }
        }
    }
}
