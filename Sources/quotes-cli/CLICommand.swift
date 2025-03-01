import Foundation
import ArgumentParser
import DotEnv
import SQLite

struct QuotesCommand: ParsableCommand {
    @Argument(help: "Theme for the quotes")
    var theme: String

    func run() {
        do {
            try DotEnv.load()
        } catch {
            print("Error: Failed to load .env file.")
            QuotesCommand.exit(withError: ExitCode(1))
        }
        
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            print("Error: OPENAI_API_KEY not set in .env file.")
            QuotesCommand.exit(withError: ExitCode(1))
        }
        
        CLIOutput.printWelcome()
        print("Theme received: \(theme)")
        
        let quoteDatabase = QuoteDatabase()
        let service = OpenAIService()
        let inputHandler = UserInputHandler()
        
        while true {
            CLIOutput.printLoading()
            let quote = service.fetchQuote(theme: theme)
            print("\nQuote: \(quote)\n")
            
            let result = inputHandler.waitForArrowKey()
            
            switch result {
            case "LEFT":
                CLIOutput.printDiscarded()
                continue
            case "RIGHT":
                quoteDatabase.saveQuote(quote)
                CLIOutput.printSuccess()
            case "EXIT":
                CLIOutput.printExit()
                QuotesCommand.exit(withError: ExitCode(0))
            default:
                print("No valid input detected. Fetching new quote...")
                continue
            }
        }
    }
}
