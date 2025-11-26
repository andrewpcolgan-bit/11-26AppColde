import SwiftUI

/// Formats interval seconds as MM:SS or :SS
struct IntervalFormatter {
    static func format(seconds: Int?) -> String {
        guard let seconds = seconds, seconds > 0 else {
            return ":00"
        }
        
        let mins = seconds / 60
        let secs = seconds % 60
        
        if mins == 0 {
            return String(format: ":%02d", secs)
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }
    
    /// Parse a digit sequence (e.g. "115") into total seconds
    /// Rules: 1-2 digits = seconds, 3+ digits = last 2 are seconds, rest are minutes
    static func parseDigits(_ digits: String) -> Int {
        guard !digits.isEmpty else { return 0 }
        let value = Int(digits) ?? 0
        
        if digits.count <= 2 {
            // Just seconds
            return value
        } else {
            // Last 2 digits are seconds, rest are minutes
            let seconds = value % 100
            let minutes = value / 100
            return minutes * 60 + seconds
        }
    }
}

/// Numeric interval keypad component
struct IntervalKeypad: View {
    @Binding var seconds: Int?
    @State private var digitBuffer: String = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // Display
            Text(IntervalFormatter.format(seconds: seconds))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(AppColor.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColor.accent.opacity(0.3), lineWidth: 1)
                        )
                )
            
            // Keypad grid
            VStack(spacing: 8) {
                ForEach(0..<3) { row in
                    HStack(spacing: 8) {
                        ForEach(1...3, id: \.self) { col in
                            let digit = row * 3 + col
                            keypadButton("\(digit)") {
                                appendDigit("\(digit)")
                            }
                        }
                    }
                }
                
                // Bottom row: Clear, 0
                HStack(spacing: 8) {
                    keypadButton("Clear", systemImage: "delete.left") {
                        clear()
                    }
                    .foregroundStyle(Color.red.opacity(0.8))
                    
                    keypadButton("0") {
                        appendDigit("0")
                    }
                    
                    // Placeholder for symmetry
                    Color.clear.frame(height: 50)
                }
            }
        }
        .onChange(of: seconds) { oldValue, newValue in
            // Reset buffer when externally changed
            // Guard against nil to prevent NaN issues
            if let newValue = newValue {
                let bufferValue = digitBuffer.isEmpty ? 0 : IntervalFormatter.parseDigits(digitBuffer)
                if newValue != bufferValue {
                    digitBuffer = ""
                }
            } else {
                digitBuffer = ""
            }
        }
    }
    
    private func keypadButton(_ label: String, systemImage: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let image = systemImage {
                    Image(systemName: image)
                        .font(.title3)
                } else {
                    Text(label)
                        .font(.title2.weight(.medium))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white.opacity(0.1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func appendDigit(_ digit: String) {
        digitBuffer += digit
        // Limit to reasonable length (e.g., 4 digits max = 99:59)
        if digitBuffer.count > 4 {
            digitBuffer = String(digitBuffer.suffix(4))
        }
        seconds = IntervalFormatter.parseDigits(digitBuffer)
    }
    
    private func clear() {
        digitBuffer = ""
        seconds = nil
    }
}
