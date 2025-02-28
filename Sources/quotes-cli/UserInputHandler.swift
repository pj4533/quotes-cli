import Foundation
import Darwin

struct UserInputHandler {
    func waitForArrowKey() -> String? {
        // Save the original terminal settings
        var originalTerm = termios()
        tcgetattr(STDIN_FILENO, &originalTerm)

        // Set terminal to raw mode
        var raw = originalTerm
        raw.c_lflag &= ~(UInt(ECHO | ICANON))
        tcsetattr(STDIN_FILENO, TCSANOW, &raw)

        defer {
            // Restore original terminal settings
            tcsetattr(STDIN_FILENO, TCSANOW, &originalTerm)
        }

        var buffer = [UInt8]()
        while true {
            var c: UInt8 = 0
            let n = read(STDIN_FILENO, &c, 1)
            if n == 1 {
                if c == 0x03 { // Ctrl+C
                    return "EXIT"
                }
                
                buffer.append(c)
                
                if buffer.count == 1 && c == 0x1B { // ESC
                    continue
                }
                
                if buffer.count == 3 && buffer[0] == 0x1B && buffer[1] == 0x5B {
                    switch buffer[2] {
                    case 0x41:
                        return "UP"
                    case 0x42:
                        return "DOWN"
                    case 0x43:
                        return "RIGHT"
                    case 0x44:
                        return "LEFT"
                    default:
                        buffer.removeAll()
                        continue
                    }
                }
                
                // Reset buffer if no valid sequence is detected
                if buffer.count >= 3 {
                    buffer.removeAll()
                }
            }
        }
    }
}
