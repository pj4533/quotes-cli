import ArgumentParser
import DotEnv

struct QuotesCommand: ParsableCommand {
    @Argument(help: "Theme for the quotes")
    var theme: String

    func run() {
        DotEnv.load()
        guard let apiKey = DotEnv.env["OPENAI_API_KEY"] else {
            print("Error: OPENAI_API_KEY not set in .env file.")
            exit(1)
        }
        print("Theme received: \(theme)")
    }
}
