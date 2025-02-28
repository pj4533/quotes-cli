import Foundation

struct CLIOutput {
    static func printWelcome() {
        let welcomeMessage = "✨ Welcome to Quotes CLI! Press ➡️ to save, ⬅️ to discard. Ctrl+C to exit. ✨"
        let cyan = "\u{001B}[0;36m" // Cyan
        let reset = "\u{001B}[0;0m"
        print("\(cyan)\(welcomeMessage)\(reset)")
    }
    
    static func printLoading() {
        let loadingMessage = "🔄 Generating quote..."
        let yellow = "\u{001B}[0;33m" // Yellow
        let reset = "\u{001B}[0;0m"
        print("\(yellow)\(loadingMessage)\(reset)")
    }
    
    static func printSuccess() {
        let successMessage = "✅ Quote saved!"
        let green = "\u{001B}[0;32m" // Green
        let reset = "\u{001B}[0;0m"
        print("\(green)\(successMessage)\(reset)")
    }
    
    static func printExit() {
        let exitMessage = "👋 Goodbye! Come back for more wisdom! ✨"
        let magenta = "\u{001B}[0;35m" // Magenta
        let reset = "\u{001B}[0;0m"
        print("\(magenta)\(exitMessage)\(reset)")
    }
}
