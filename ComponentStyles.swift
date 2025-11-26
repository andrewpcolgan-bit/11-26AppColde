//
//  ComponentStyles.swift
//  SwimSetTracker
//
//  Created by Antigravity on 11/22/25.
//

import SwiftUI

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body.weight(.semibold))
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(AppColor.accent.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body.weight(.semibold))
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(AppColor.surfaceThin)
            .foregroundColor(.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColor.border, lineWidth: 1)
            )
    }
}

// MARK: - Chips

struct SelectableChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.caption)
                .foregroundColor(.white)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: AppLayout.chipRadius)
                        .fill(isSelected ? AppColor.accent.opacity(0.9) : AppColor.surfaceThin)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.chipRadius)
                        .stroke(isSelected ? AppColor.accent : AppColor.borderLight)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dividers

struct AccentDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [AppColor.accent.opacity(0.0), AppColor.accent.opacity(0.5), AppColor.accent.opacity(0.0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}
