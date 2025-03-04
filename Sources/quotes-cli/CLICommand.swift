import Foundation
import ArgumentParser
import DotEnv
import os

@main
struct QuotesCommand: AsyncParsableCommand {
    @Argument(help: "Theme for the quotes")
    var theme: String?
    
    @Option(name: .shortAndLong, help: "AI service to use (openai or anthropic)")
    var service: String?
    
    @Flag(name: [.short, .long], help: "Enable verbose logging.")
    var verbose: Bool = false
    
    private static let logger = Logger(subsystem: "com.yourapp.quotes-cli", category: "CLICommand")

    func run() async throws {
        Self.logger.notice("🚀 Starting quotes-cli application")
        
        do {
            let path = FileManager.default.currentDirectoryPath + "/.env"
            Self.logger.debug("Loading .env file from: \(path)")
            try DotEnv.load(path: path)
            Self.logger.debug("Successfully loaded .env file")
        } catch {
            Self.logger.error("❌ Failed to load .env file: \(error.localizedDescription)")
            QuotesCommand.exit(withError: ExitCode(1))
        }
        
        // Check for required API keys based on service type
        let serviceType = AIServiceType.fromString(service)
        if serviceType == .openAI {
            guard ProcessInfo.processInfo.environment["OPENAI_API_KEY"] != nil else {
                Self.logger.error("OPENAI_API_KEY not set in .env file.")
                QuotesCommand.exit(withError: ExitCode(1))
            }
        } else if serviceType == .anthropic {
            guard ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] != nil else {
                Self.logger.error("ANTHROPIC_API_KEY not set in .env file.")
                QuotesCommand.exit(withError: ExitCode(1))
            }
        }
        
        if verbose {
            print("Verbose mode enabled")
            Self.logger.debug("Verbose mode enabled")
        }
        
        CLIOutput.printWelcome()
        
        let quoteDatabase = QuoteDatabase()
        // Configure logger level based on verbose flag
        if verbose {
            Self.logger.debug("Verbose logging enabled")
        }
        
        // Using the already defined serviceType
        Self.logger.notice("Using AI service: \(serviceType.rawValue)")
        
        let aiService = AIServiceFactory.createService(type: serviceType)
        let inputHandler = UserInputHandler()
        
        while true {
            CLIOutput.printLoading()
            do {
                Self.logger.notice("🔄 Fetching new quote")
                let quote = try await aiService.fetchQuote(theme: theme, verbose: verbose)
                print("\n\u{001B}[1m\u{001B}[37m\(quote)\u{001B}[0m\n")
                
                Self.logger.debug("Waiting for user input")
                let result = inputHandler.waitForArrowKey()
                Self.logger.debug("Received user input: \(result ?? "nil")")
                
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
                    Self.logger.debug("No valid input detected. Quitting...")
                    QuotesCommand.exit(withError: ExitCode(0))
                }
            } catch {
                Self.logger.error("❌ Error fetching quote: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    Self.logger.error("Error domain: \(nsError.domain), code: \(nsError.code)")
                    if let details = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                        Self.logger.error("Error details: \(details)")
                    }
                }
                Self.logger.error("Error: \(error.localizedDescription)")
                
                // Log more detailed error information
                if let nsError = error as NSError? {
                    Self.logger.error("Error Details:")
                    Self.logger.error("  Domain: \(nsError.domain)")
                    Self.logger.error("  Code: \(nsError.code)")
                    
                    if let details = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                        Self.logger.error("  Description: \(details)")
                    }
                }
                
                // Still print the error for user visibility
                print("\n\u{001B}[1;31mError: \(error.localizedDescription)\u{001B}[0m")
                print("\nPress any key to try again or Ctrl+C to exit...")
                _ = inputHandler.waitForArrowKey()
                continue
            }
        }
    }
}
