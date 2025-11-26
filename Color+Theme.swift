import SwiftUI

extension Color {
    // Near-black background for main views
    static let appBackground = Color(hex: "050505")
    
    // Glassy dark card background (black with 0.3–0.4 opacity over material)
    static let cardBackground = Color.black.opacity(0.4)
    
    // White with ~0.18–0.24 opacity for card borders
    static let cardStroke = Color.white.opacity(0.18)
    
    // The app’s teal accent (primary brand color)
    static let appAccent = Color(hex: "00E5FF") // Bright Teal
    
    // Softer teal for subtle highlights
    static let appAccentSoft = Color(hex: "00E5FF").opacity(0.3)
    
    // Text Colors
    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.7)
    static let textMuted = Color.white.opacity(0.55)
    
    // Status Colors
    static let positive = Color(hex: "00FF9D") // Bright Green
    static let warning = Color(hex: "FFB300") // Amber/Orange
    static let danger = Color(hex: "FF3B30") // Red
}

// Helper for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
