//
//  UIComponents.swift
//  SwimSetTracker
//

import SwiftUI

// MARK: - Reusable UI Components

// MARK: - Reusable UI Components

struct AppCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(AppLayout.padding)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
    }
}

struct CardHeader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(AppFont.cardTitle)
            .foregroundStyle(.white)
            .padding(.bottom, 4)
    }
}

struct LegendRow: View {
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
            
            Text(title)
                .font(AppFont.body)
                .foregroundStyle(.white)
            
            Spacer()
            
            Text(detail)
                .font(AppFont.body)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.vertical, 4)
    }
}

struct BreakdownStyledView: View {
    let title: String
    let sets: [String]
    let totalYards: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.accent)
                Spacer()
                Text("\(totalYards) yds")
                    .font(AppFont.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(sets, id: \.self) { set in
                    Text(set)
                        .font(.system(.body, design: .monospaced)) // Keep monospaced for sets
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.leading, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColor.surfaceThin)
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColor.surfaceThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColor.borderLight, lineWidth: 1)
                )
        )
    }
}



