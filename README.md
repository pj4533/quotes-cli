# Quotes CLI

✨ **Welcome to Quotes CLI!** ✨

**Quotes CLI** is a Swift-based command-line application that generates short, compelling AI-generated quotes based on user-defined themes. Leveraging OpenAI's GPT-4o via the Chat Completions API, Quotes CLI offers an interactive and seamless experience for users to discover and save inspiring quotes directly from their terminal.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

## Features

- **AI-Generated Quotes:** Generate unique and inspiring quotes tailored to your chosen theme.
- **Interactive Controls:**
  - **Right Arrow (👉):** Save the displayed quote to a local SQLite database.
  - **Left Arrow (👈):** Discard the current quote and fetch a new one.
- **Styled Terminal Output:** Enjoy a visually appealing interface with ANSI colors and emojis.
- **Continuous Operation:** The application runs continuously, fetching new quotes until you decide to exit with **Ctrl+C**.
- **Local Storage:** Persist your favorite quotes in a local SQLite database (`quotes.db`) for future reference.

## Installation

### Prerequisites

- **Swift 6.0 or later:** Ensure you have Swift installed on your system. You can download it from [Swift.org](https://swift.org/download/).
- **SQLite:** SQLite is required for local storage. It's typically pre-installed on macOS and Linux systems.

### Steps

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/your-username/quotes-cli.git
   cd quotes-cli
   ```

2. **Set Up Environment Variables:**

   - Create a `.env` file in the root directory:
     ```
     OPENAI_API_KEY=your_openai_api_key_here
     ```
   - Replace `your_openai_api_key_here` with your actual OpenAI API key.

3. **Build the Application:**

   ```bash
   swift build -c release
   ```

4. **Run the Application:**

   ```bash
   .build/release/quotes-cli "your_theme_here"
   ```

   Replace `"your_theme_here"` with the theme you want the quotes to embody (e.g., `"surreal inspirational"`).

## Usage

Once the application is running, you'll see the following welcome message:

