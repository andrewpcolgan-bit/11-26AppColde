//
//  DesignSystem.swift
//  SwimSetTracker
//
//  Created by Antigravity on 11/22/25.
//

import SwiftUI

// MARK: - 1.1 Colors

enum AppColor {
    static let background = Color.black
    static let surface = Color.white.opacity(0.10)
    static let surfaceThin = Color.white.opacity(0.06)
    static let border = Color.white.opacity(0.20)
    static let borderLight = Color.white.opacity(0.10)
    static let accent = Color(red: 0.18, green: 0.85, blue: 0.80)  // teal tone
    static let accentSecondary = Color(red: 0.22, green: 0.45, blue: 0.90)
    static let danger = Color.red
    static let success = Color.green
    static let cardBackground = Color.white.opacity(0.10)
}

// MARK: - 1.2 Typography



// MARK: - 1.3 Spacing + Radius Tokens

enum AppLayout {
    static let cardRadius: CGFloat = 18
    static let chipRadius: CGFloat = 12
    static let padding: CGFloat = 16
    static let innerSpacing: CGFloat = 10
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
