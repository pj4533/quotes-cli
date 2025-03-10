import Foundation
import os

/// Shared logic for generating quotes across different AI services
class QuoteGenerator {
    private let logger = Logger(subsystem: "com.yourapp.quotes-cli", category: "QuoteGenerator")
    private var savedQuotes: [String] = []
    
    /// Adds a quote to the saved quotes collection
    /// - Parameter quote: The quote to save
    func saveQuote(_ quote: String) {
        savedQuotes.append(quote)
        logger.debug("Added quote to saved collection: \(quote)")
    }
    
    /// Generates a prompt for the AI service
    /// - Parameters:
    ///   - theme: Optional theme for the quote
    ///   - verbose: Whether to print verbose output
    /// - Returns: A tuple containing the prompt and an empty string (for backward compatibility)
    func generatePrompt(theme: String?, verbose: Bool) -> (prompt: String, inspiration: String) {
        var prompt: String
        
        if let theme = theme, !theme.isEmpty {
            prompt = """
            Provide a short, compelling quote that embodies the themes of \(theme). \
            Keep it under 5 words.
            """
        } else {
            prompt = """
            Provide a short, compelling quote that uses a random theme. \
            Keep it under 5 words.
            """
        }
        
        // If we have saved quotes, include them in the prompt
        if !savedQuotes.isEmpty {
            prompt += """
            
            The user has previously liked these quotes:
            """
            
            // Add each quote on a separate line with a number and clear formatting
            for (index, quote) in savedQuotes.enumerated() {
                prompt += """
                
                Quote #\(index + 1): "\(quote)"
                """
            }
            
            prompt += """
            
            Generate a new, different quote that has a similar style or quality to these liked quotes.
            The new quote should NOT be identical to any of the liked quotes.
            """
        }
        
        if verbose {
            logger.debug("Prompt used: \(prompt)")
            print("Prompt used: \(prompt)")
        }
        
        return (prompt, "")
    }
    
    /// Cleans a quote by removing whitespace and quotes
    /// - Parameter quote: The raw quote from the AI service
    /// - Returns: A cleaned quote
    func cleanQuote(_ quote: String) -> String {
        return quote.trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
    
    /// Logs response headers and rate limit information
    /// - Parameters:
    ///   - httpResponse: The HTTP response
    ///   - rateLimitHeaders: Array of header keys to look for rate limit information
    ///   - verbose: Whether to print verbose output
    ///   - logger: The logger to use
    static func logResponseHeaders(
        httpResponse: HTTPURLResponse,
        rateLimitHeaders: [String],
        verbose: Bool,
        logger: Logger
    ) {
        logger.debug("Response status code: \(httpResponse.statusCode)")
        logger.debug("--- Response Headers ---")
        
        // Only print headers in verbose mode
        if verbose {
            logger.info("📋 Response Headers:")
            print("\n📋 Response Headers:")
            
            for (key, value) in httpResponse.allHeaderFields {
                let keyString = String(describing: key)
                let valueString = String(describing: value)
                logger.debug("\(keyString): \(valueString)")
                print("  \(keyString): \(valueString)")
            }
            
            logger.info("⚠️ Rate Limit Information:")
            print("\n⚠️ Rate Limit Information:")
            var foundRateLimitHeaders = false
            
            for header in rateLimitHeaders {
                if let value = httpResponse.allHeaderFields[header] {
                    let valueString = String(describing: value)
                    logger.notice("\(header): \(valueString)")
                    print("  \(header): \(valueString)")
                    foundRateLimitHeaders = true
                }
            }
            
            if !foundRateLimitHeaders {
                logger.info("No specific rate limit headers found")
                print("  No specific rate limit headers found")
            }
            print("")
        }
    }
}
