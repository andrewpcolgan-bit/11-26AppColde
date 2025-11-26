//
//  ErrorBanner.swift
//  SwimSetTracker
//
//  Created by Antigravity on 11/22/25.
//

import SwiftUI

struct ErrorBanner: View {
    let title: String
    let message: String

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColor.danger)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFont.body.weight(.semibold))
                        .foregroundColor(.white)

                    Text(message)
                        .font(AppFont.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
    }
}

#Preview {
    ZStack {
        AppColor.background.ignoresSafeArea()
        ErrorBanner(title: "Network Error", message: "Check your connection and try again.")
            .padding()
    }
}
