import Foundation
import ArgumentParser
import DotEnv
import os

@main
struct QuotesCommand: AsyncParsableCommand {
    @Argument(help: "Theme for the quotes")
    var theme: String?
    
    private let logger = Logger(subsystem: "com.yourapp.quotes-cli", category: "CLICommand")

    func run() async throws {
        do {
            let path = FileManager.default.currentDirectoryPath + "/.env"
            try DotEnv.load(path: path)
        } catch {
            logger.error("Failed to load .env file: \(error.localizedDescription)")
            QuotesCommand.exit(withError: ExitCode(1))
        }
        
        guard ProcessInfo.processInfo.environment["OPENAI_API_KEY"] != nil else {
            logger.error("OPENAI_API_KEY not set in .env file.")
            QuotesCommand.exit(withError: ExitCode(1))
        }
        
        CLIOutput.printWelcome()
        
        let quoteDatabase = QuoteDatabase()
        let service = OpenAIService()
        let inputHandler = UserInputHandler()
        
        while true {
            CLIOutput.printLoading()
            do {
                let quote = try await service.fetchQuote(theme: theme)
                print("\n\u{001B}[1m\u{001B}[37m\(quote)\u{001B}[0m\n")
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
                    logger.debug("No valid input detected. Quitting...")
                    QuotesCommand.exit(withError: ExitCode(0))
                }
            } catch {
                logger.error("Error fetching quote: \(error.localizedDescription)")
                QuotesCommand.exit(withError: ExitCode(0))
            }
        }
    }
}
