import ArgumentParser

struct QuotesCommand: ParsableCommand {
    @Argument(help: "Theme for the quotes")
    var theme: String

    func run() {
        print("Theme received: \(theme)")
    }
}
