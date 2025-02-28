# AI Quote Generator CLI - Developer Specification

## Overview
The AI Quote Generator CLI is a command-line application written in Swift that generates short, compelling AI-generated quotes based on user input. It interacts with OpenAI's GPT-4o via the Chat Completions API. Users can interact with the application using **left arrow (👈) to discard** or **right arrow (👉) to save** quotes. Liked quotes are stored in a local SQLite database.

The application runs **continuously** until the user presses **Ctrl+C to exit**, ensuring a smooth, uninterrupted experience.

---
## Requirements
### 1. Functional Requirements
- Accept a **single text parameter** that describes the theme of the quote (e.g., `quotes "surreal inspirational"`).
- Call OpenAI's **GPT-4o** API with the structured prompt:
  > "Provide a short, compelling quote that embodies the themes of {user input}. Keep it under 20 words."
- **Styled output**: Display quotes with **ANSI colors and emojis**.
- **User interactions:**
  - **Right arrow (👉)** → Saves the quote to `quotes.db`.
  - **Left arrow (👈)** → Discards the quote and fetches a new one.
- **Runs continuously** until exited via **Ctrl+C**.
- **Displays a welcome message** at startup:
  ```
  ✨ Welcome to Quotes CLI! Press ➡️ to save, ⬅️ to discard. Ctrl+C to exit. ✨
  ```
- **Animated loading effect** (`🔄 Generating quote...`) while waiting for the API response.
- **Confirms saved quotes** with a single-line message (`✅ Quote saved!`), ensuring minimal screen clutter.
- **No artificial delays, no sounds, no manual refresh (no skipping with spacebar)**.

### 2. Non-Functional Requirements
- **Performance:** Instant response as soon as the API returns a quote.
- **Reliability:** If OpenAI API fails, display the error and exit.
- **Portability:** Runs on any macOS/Linux terminal supporting Swift.
- **Minimalistic:** No extra dependencies beyond **Swift Package Manager (SPM)** and SQLite.

---
## Architecture & Implementation Details
### 1. **Technology Stack**
- **Language**: Swift (CLI-focused implementation).
- **Dependency Manager**: Swift Package Manager (SPM).
- **Argument Parsing**: `ArgumentParser` (official Swift package).
- **Environment Variables**: `swift-dotenv` to load `OPENAI_API_KEY` from a `.env` file.
- **SQLite Database**: `SQLite.swift` for local storage.
- **Terminal UI Enhancements**: ANSI escape codes for colored output and single-line updates.

### 2. **Project Structure**
```
quotes-cli/
├── Sources/
│   ├── main.swift      # Entry point for CLI execution
│   ├── OpenAIService.swift  # Handles API requests
│   ├── QuoteDatabase.swift  # SQLite wrapper for saving quotes
│   ├── UserInputHandler.swift  # Handles key press events
│   ├── CLIOutput.swift  # Manages styled terminal output
├── .env                # Stores API key (ignored in Git)
├── Package.swift       # SPM dependencies and configuration
└── README.md           # Project documentation
```

### 3. **Data Handling**
#### **OpenAI API Integration**
- Load API key from `.env` using `swift-dotenv`.
- Make a `POST` request to OpenAI’s **Chat Completions API (GPT-4o)**.
- Parse JSON response to extract the quote text.
- Handle errors (e.g., invalid API key, rate limits).

#### **SQLite Database Schema**
**Table Name:** `quotes`
| Column      | Type      | Description                      |
|------------|----------|----------------------------------|
| `id`       | INTEGER  | Primary Key (auto-increment)    |
| `quote`    | TEXT     | The AI-generated quote          |
| `created_at` | TIMESTAMP | The timestamp when it was liked |

- Database file: `quotes.db` (stored in the current working directory).
- If `quotes.db` does not exist, it is automatically created.
- **No duplicate checking**—all liked quotes are stored as-is.

### 4. **Error Handling Strategy**
| Error Case | Handling Strategy |
|------------|------------------|
| API Key Missing | Print error in red, exit immediately |
| Network Issue | Print error in red, exit immediately |
| API Rate Limit | Print error in red, exit immediately |
| OpenAI API Failure | Print error in red, exit immediately |
| Database Error | Print error in red, exit immediately |

Example error output:
```
❌ OpenAI Rate Limit Exceeded. Please wait a moment and try again. 🔴
```
```
❌ Database Error: Failed to save quote. Check your database file (quotes.db). 🔴
```

---
## User Experience & Terminal UI Design
### 1. **Welcome Screen**
```
✨ Welcome to Quotes CLI! Press ➡️ to save, ⬅️ to discard. Ctrl+C to exit. ✨
```
### 2. **Loading Animation** (while waiting for API response)
```
🔄 Generating quote...
```
### 3. **Quote Display (Styled Output)**
```
🤯 "The sky isn’t above you, it’s inside you."
```
### 4. **Quote Saved Confirmation (Single-Line Update)**
```
✅ Quote saved! (stays on the same line, preventing scrolling mess)
```
### 5. **Exit Message on Ctrl+C**
```
👋 Goodbye! Come back for more wisdom! ✨
```

---
## Testing Plan
### 1. **Unit Tests**
- **OpenAIService Tests**
  - Mock API responses (valid quote, network failure, rate limits).
- **Database Tests**
  - Verify quotes are stored correctly.
  - Ensure DB initializes properly.
- **UserInputHandler Tests**
  - Simulate left/right arrow key presses.
  - Ensure unknown keys are ignored.
- **CLIOutput Tests**
  - Validate styled ANSI output formatting.

### 2. **Manual Testing**
| Test Case | Expected Behavior |
|-----------|-------------------|
| Run `quotes "surreal inspirational"` | Generates and displays a quote |
| Press Right Arrow (👉) | Saves the quote to `quotes.db` |
| Press Left Arrow (👈) | Discards quote, fetches new one |
| Press Unknown Key | No response, waits for valid input |
| Press Ctrl+C | Exits gracefully with goodbye message |
| No `.env` file / Invalid API Key | Displays error, exits |
| Network disconnected | Displays error, exits |
| API rate limit hit | Displays error, exits |
| `quotes.db` write failure | Displays error, exits |

---
## Conclusion
This specification provides **everything a developer needs** to build the AI Quote Generator CLI. The app is designed to be **minimalist, responsive, and interactive**, ensuring a great user experience. **No unnecessary features**, just clean execution with a simple left/right approval system. 🚀

