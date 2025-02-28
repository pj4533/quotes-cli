Below is a structured approach to designing and implementing the **AI Quote Generator CLI** project. We’ll go through **three rounds**:

1. **Draft a high-level blueprint** (major phases).
2. **Break into iterative chunks** (each chunk with a clear goal and some sub-steps).
3. **Finally, refine each chunk into minimal actionable steps** (that a code-generation LLM can tackle).

After that, we’ll provide a **series of prompts**—one per chunk—that you can feed into a code-generation LLM to implement the project **incrementally**. Each prompt explicitly builds on the previous steps and integrates with the code that’s already been generated, ensuring no “orphaned” or unconnected code.

---

## **Round 1: High-Level Blueprint**

1. **Initialize Project & Dependencies**  
   - Set up an SPM-based Swift project (`quotes-cli`).  
   - Configure `Package.swift` with required dependencies (ArgumentParser, swift-dotenv, SQLite.swift).

2. **Implement Argument Parsing**  
   - Use Swift’s `ArgumentParser` to capture the user’s input (the quote theme, e.g., `"surreal inspirational"`).

3. **Load Environment Variables**  
   - Integrate `swift-dotenv` to load the `OPENAI_API_KEY` from a `.env` file.  
   - Fail fast (exit) if the key is missing.

4. **Build the OpenAI Service**  
   - Create a Swift struct/class (`OpenAIService`) that calls OpenAI’s Chat Completions API (GPT-4o).  
   - Handle HTTP requests, parse JSON responses, handle errors.

5. **Handle Real-Time User Input**  
   - Implement a `UserInputHandler` that can detect arrow key presses (left, right).  
   - Distinguish between arrow keys and other inputs (ignore other keys).  
   - Stop on Ctrl+C.

6. **Set Up SQLite Database**  
   - Create `quotes.db` and a table (`quotes`) if not existing.  
   - Implement insertion methods to save liked quotes.

7. **CLI Output and Styling**  
   - Create a `CLIOutput` module that handles printing with ANSI colors, emojis, and minimal line clutter.  
   - Includes a loading indicator (`🔄 Generating quote...`) and success notifications (`✅ Quote saved!`).

8. **Tie Everything Together**  
   - In `main.swift`, orchestrate the steps:  
     1. Parse user theme.  
     2. Call OpenAI API with theme.  
     3. Display quote.  
     4. Wait for arrow keys → discard or save.  
     5. Loop until Ctrl+C.  
   - Ensure robust error handling (API, DB, etc.) and graceful exits.

---

## **Round 2: Break Into Iterative Chunks**

Below is a proposed breakdown of the major phases into smaller, sequential chunks. Each chunk ends with working code that **integrates** into the overall project:

1. **Chunk A**: **Create SPM Project & Basic Structure**  
   - Initialize new Swift package.  
   - Add baseline folders/files (`main.swift`, `README.md`).  
   - Verify compilation with `swift build`.

2. **Chunk B**: **Add Argument Parsing**  
   - Include `ArgumentParser` in `Package.swift`.  
   - Implement a simple command that prints the user’s input.

3. **Chunk C**: **Environment Variable Loading**  
   - Add `swift-dotenv` to `Package.swift`.  
   - Load `OPENAI_API_KEY` from `.env` file.  
   - Confirm reading/writing environment variables works.

4. **Chunk D**: **OpenAIService - Minimal Integration**  
   - Create `OpenAIService` struct/class with a stub function (`fetchQuote(theme:)`) that **hardcodes** a single-line JSON response.  
   - Return the “quote” from the stub.  
   - Print the fetched quote.

5. **Chunk E**: **OpenAIService - Real HTTP Implementation**  
   - Convert the stub function to a real API call to GPT-4o.  
   - Send the structured prompt.  
   - Parse JSON response for the generated quote.  
   - Handle possible errors.

6. **Chunk F**: **Keyboard Event Handling**  
   - Implement a simple loop that reads key presses.  
   - Print messages for arrow keys (left vs. right).  
   - Stop on Ctrl+C (or command–`.` on Mac, etc.).

7. **Chunk G**: **SQLite Database Integration**  
   - Add `SQLite.swift` to `Package.swift`.  
   - Create a `QuoteDatabase` class to handle initialization and `saveQuote` methods.  
   - Ensure it creates `quotes.db` and the `quotes` table if not present.

8. **Chunk H**: **Bringing User Input, OpenAI, and DB Together**  
   - In `main.swift`, orchestrate:  
     1. Prompt user for theme (via arguments).  
     2. Fetch quote from OpenAI.  
     3. Display quote.  
     4. Wait for arrow key → if right arrow, store in DB; if left arrow, discard.  
     5. Loop until Ctrl+C.

9. **Chunk I**: **CLI Styling & Finishing Touches**  
   - Add ANSI colors, emojis for the loading and success messages.  
   - Add welcome/exit messages.  
   - Final error handling (API missing key, DB write failures, etc.).  
   - Ready for final testing.

---

## **Round 3: Refine Each Chunk Into Actionable Steps**

Now we refine each chunk into smaller, safe steps that move the project forward **iteratively** without large jumps in complexity.

### **Chunk A**: Create SPM Project & Basic Structure
1. **Initialize** the Swift package: `swift package init --type executable`.
2. **Organize** folder structure: confirm `Sources/quotes-cli/main.swift` is our entry point.
3. **Test** by running `swift build` and `swift run`.

### **Chunk B**: Add Argument Parsing
1. **Update** `Package.swift` to include `ArgumentParser` as a dependency.
2. **Create** a new file `CLICommand.swift` that imports `ArgumentParser` and defines a struct (e.g., `QuotesCommand`).
3. **Implement** a basic run method that prints the user’s input (`theme`).
4. **Modify** `main.swift` to invoke `QuotesCommand.main()`.

### **Chunk C**: Environment Variable Loading
1. **Add** `swift-dotenv` dependency in `Package.swift`.
2. **Create** a `.env` file with `OPENAI_API_KEY=YOUR_API_KEY`.
3. **Load** environment variables in `main.swift` or inside `QuotesCommand`, ensuring we can read `OPENAI_API_KEY`.
4. **Fail** gracefully if the key is missing.

### **Chunk D**: OpenAIService - Minimal Integration
1. **Create** `OpenAIService.swift` with a stub function `fetchQuote(theme: String) -> String`.
2. **Return** a hardcoded JSON string (or a plain string) as a placeholder quote.
3. **Integrate** `OpenAIService` in `QuotesCommand` to fetch and print a dummy quote.

### **Chunk E**: OpenAIService - Real HTTP Implementation
1. **Add** real logic to `fetchQuote(theme: String)`.
2. **Use** `URLSession` or a Swift HTTP library to call OpenAI’s Chat Completions endpoint.
3. **Construct** the request body with the prompt:
   ```
   "Provide a short, compelling quote that embodies the themes of {theme}. Keep it under 20 words."
   ```
4. **Parse** the JSON response to extract the generated quote text.
5. **Handle** any HTTP or JSON errors, returning them gracefully.

### **Chunk F**: Keyboard Event Handling
1. **Create** `UserInputHandler.swift` to manage terminal keyboard input.
2. **Implement** logic for reading arrow keys. (Left = discard, Right = save.)
3. **Loop** waiting for the user to press an arrow key or exit with Ctrl+C.
4. **Test** by printing messages (e.g., “Left arrow detected!”).

### **Chunk G**: SQLite Database Integration
1. **Add** `SQLite.swift` to `Package.swift`.
2. **Create** `QuoteDatabase.swift` with `init()` that opens/creates `quotes.db`.
3. **Create** a `createTable()` function for the `quotes` table.
4. **Add** `saveQuote(_ quote: String)` method to insert a quote into the table.
5. **Test** by saving a dummy quote.

### **Chunk H**: Bringing User Input, OpenAI, and DB Together
1. **Modify** `QuotesCommand.run()`:
   - Get the theme from arguments.
   - Start a loop:  
     a. Call `OpenAIService.fetchQuote(theme)`  
     b. Print the quote.  
     c. Wait for arrow key input.  
     d. If Right arrow, save quote to DB; if Left arrow, discard.  
2. **Keep** generating new quotes until user presses Ctrl+C (or kills the program).
3. **Add** break condition and graceful shutdown message.

### **Chunk I**: CLI Styling & Finishing Touches
1. **Create** `CLIOutput.swift` to centralize ANSI styling methods.
2. **Use** emojis and colors for the welcome message, loading, quotes, success messages, error messages.
3. **Integrate** short disclaimers or logs for error handling (e.g., “❌ Network error. Exiting.”).
4. **Perform** final checks: environment checks, DB checks, error paths.
5. **Finalize** with a stable, minimal CLI tool.

---

## **Prompts for a Code-Generation LLM**

Below is a set of **step-by-step prompts** you can use to build this project **incrementally**. Each prompt is a Markdown section with a code block containing the exact text you’d provide to the code-generation LLM. They are structured so that each piece of code naturally **builds upon the previously generated code** without leaving orphan code.

> **Important:** You may need to tweak references to file names depending on how your LLM handles multi-file outputs.

---

### **Prompt A: SPM Project & Basic Structure**

````text
You are a code-generation assistant. I want to create a Swift CLI project called "quotes-cli" using the Swift Package Manager. Generate the following:

1. A new Swift package initialized as an executable.
2. A `main.swift` file in `Sources/quotes-cli/` that prints "Hello from quotes-cli!" just to confirm it works.
3. A `README.md` with a one-line project description.

No additional logic is needed yet. Provide all relevant files.
````

---

### **Prompt B: Add Argument Parsing**

````text
We now have a basic SPM project. Next steps:

1. Update `Package.swift` to include the `swift-argument-parser` dependency.
2. Add a new file `CLICommand.swift` that imports `ArgumentParser`. 
3. Create a struct named `QuotesCommand` conforming to ParsableCommand with a single `theme` argument (type String).
4. In `main.swift`, replace any "Hello" code with `QuotesCommand.main()` call.
5. When someone runs `quotes-cli "surreal inspirational"`, the program should print: "Theme received: surreal inspirational".

Generate the updated `Package.swift`, `CLICommand.swift`, and `main.swift`.
````

---

### **Prompt C: Environment Variable Loading**

````text
Now let's add environment variable loading:

1. In `Package.swift`, add `swift-dotenv` as a dependency (point to its GitHub repo).
2. Create a `.env` file at the root with a placeholder `OPENAI_API_KEY=YOUR_API_KEY`.
3. In `CLICommand.swift`, load the `.env` file using DotEnv, then read `OPENAI_API_KEY`.
4. If `OPENAI_API_KEY` doesn't exist, print an error and exit.

Generate the relevant updates to `Package.swift`, `.env`, and `CLICommand.swift`.
````

---

### **Prompt D: OpenAIService - Minimal Integration**

````text
We will introduce a stub for the OpenAIService:

1. Create `OpenAIService.swift` with a struct `OpenAIService`.
2. Add a function `func fetchQuote(theme: String) -> String` that returns a hard-coded string, for now: "Hardcoded test quote."
3. In `CLICommand.swift`, after successfully reading the API key, instantiate `OpenAIService` and call `fetchQuote(theme:)`, printing the returned result.

Generate `OpenAIService.swift` and the modified `CLICommand.swift`.
````

---

### **Prompt E: OpenAIService - Real HTTP Implementation**

````text
Now we replace the stub with a real call to OpenAI's Chat Completions API (GPT-4o). Steps:

1. In `OpenAIService.swift`, replace the hard-coded return with:
   - A `URLRequest` to the Chat Completions endpoint, using `OPENAI_API_KEY` as the Bearer token.
   - JSON body with the prompt: "Provide a short, compelling quote that embodies the themes of {theme}. Keep it under 20 words."
   - Parse the JSON response to extract the quote text (assume the API returns an array of choices with a `message.content` string).
2. Handle errors (HTTP error, missing response, etc.). If there's an error, return something like "Error: <description>" so we can see it for now.

Generate the updated `OpenAIService.swift`. Show how you handle the request and parsing. Ensure you adapt to GPT-4 or GPT-3.5 style responses. 
````

---

### **Prompt F: Keyboard Event Handling**

````text
We want arrow key detection. Steps:

1. Create a new file: `UserInputHandler.swift` with a function `func waitForArrowKey() -> String?`, which:
   - Blocks until we get either left arrow, right arrow, or Ctrl+C (detectable via SIGINT).
   - Returns "LEFT", "RIGHT", or "EXIT" accordingly.
2. For now, just demonstrate usage in `CLICommand.swift` by calling `waitForArrowKey()` once after fetching a quote, printing the result.

Generate `UserInputHandler.swift` and the updated `CLICommand.swift`. 
Use standard Swift or a small C wrapper approach to read raw terminal input. 
If detection logic is too complex, comment with a high-level explanation, and we can refine further.
````

---

### **Prompt G: SQLite Database Integration**

````text
Now we'll save quotes locally in `quotes.db`:

1. Add `SQLite.swift` to `Package.swift` dependencies.
2. Create `QuoteDatabase.swift` with:
   - An initializer that opens or creates `quotes.db`.
   - A `createTable()` method for `quotes` table with schema: id (INTEGER PRIMARY KEY), quote (TEXT), created_at (TIMESTAMP).
   - A `saveQuote(_ quote: String)` method to insert a new record.
3. In `CLICommand.swift`, create a global or class-level instance of `QuoteDatabase`.
4. For now, call `saveQuote("Test quote")` once to confirm it works.

Generate the updated `Package.swift`, `QuoteDatabase.swift`, and the changes to `CLICommand.swift`.
````

---

### **Prompt H: Integrate Quote Saving With Arrow Keys**

````text
Time to tie it all together:

1. In `CLICommand.swift`:
   - Parse the user’s theme from arguments.
   - Continuously call `OpenAIService.fetchQuote(theme)`.
   - Print the quote.
   - Wait for arrow key: 
     - If LEFT, discard and fetch a new quote.
     - If RIGHT, save to database (with the current quote).
   - Keep looping until user hits Ctrl+C (EXIT).
2. Print a short message "Quote saved!" when the user presses RIGHT.
3. Print "Discarded. Fetching new quote..." when the user presses LEFT.

Generate the revised `CLICommand.swift` that handles this loop and logic. If needed, refine `UserInputHandler.swift` so it returns "EXIT" on Ctrl+C and breaks the loop with a goodbye message.
````

---

### **Prompt I: CLI Styling & Finishing Touches**

````text
Add final polish:

1. Create `CLIOutput.swift` or a simple set of extension methods for colored/emojis output.
2. Use:
   - A welcome message with emojis at the start: 
     ```
     ✨ Welcome to Quotes CLI! Press ➡️ to save, ⬅️ to discard. Ctrl+C to exit. ✨
     ```
   - A loading indicator with: 
     ```
     🔄 Generating quote...
     ```
   - A success message when a quote is saved: 
     ```
     ✅ Quote saved!
     ```
3. Print an exit message when Ctrl+C is pressed, e.g.:
   ```
   👋 Goodbye! Come back for more wisdom! ✨
   ```

Generate the updated code (new or modified files) to include ANSI color escape sequences where appropriate. 
No artificial delays. We are done after verifying all steps work properly.
````

---

## **Final Note**

By following these prompts **in order**, you can build the AI Quote Generator CLI **incrementally**. Each prompt ensures that code is integrated and there are no dangling or unused pieces. You should end up with a fully functional Swift-based CLI tool that:

- **Parses** user input to capture a quote theme,
- **Calls** OpenAI’s GPT model to generate short quotes,
- **Lets** users discard or save quotes via arrow keys,
- **Stores** liked quotes in a local SQLite database,
- **Displays** all interactions with minimal but elegant terminal styling.

Happy coding!