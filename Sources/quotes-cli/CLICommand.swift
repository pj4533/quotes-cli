import Foundation
import ArgumentParser
import DotEnv

@main
struct QuotesCommand: AsyncParsableCommand {
    @Argument(help: "Theme for the quotes")
    var theme: String

    func run() async throws {
        do {
            let path = FileManager.default.currentDirectoryPath + "/.env"
            try DotEnv.load(path: path)
        } catch {
            print("Error: Failed to load .env file.")
            QuotesCommand.exit(withError: ExitCode(1))
        }
        
        guard ProcessInfo.processInfo.environment["OPENAI_API_KEY"] != nil else {
            print("Error: OPENAI_API_KEY not set in .env file.")
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
                    print("No valid input detected. Quitting...")
                    QuotesCommand.exit(withError: ExitCode(0))
                }
            } catch {
                print("Error fetching quote: \(error.localizedDescription)")
                QuotesCommand.exit(withError: ExitCode(0))
            }
        }
    }
}
