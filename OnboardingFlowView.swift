//
//  OnboardingFlowView.swift
//  SwimSetTracker
//
//  Created by Antigravity on 11/22/25.
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var appData: AppData

    /// Called when onboarding finishes – the App sets hasCompletedOnboarding.
    var onFinished: () -> Void = {}

    // 0: splash, 1: tour, 2: profile, 3: weekly rhythm
    @State private var step: Int = 0
    @State private var featurePage: Int = 0

    // Profile
    @State private var swimmerType: String = "College swimmer" // primary label
    @State private var selectedSwimmerTypes: Set<String> = ["College swimmer"] // multi-select
    @State private var primaryFocus: String = "Mid-distance"
    @State private var poolUnit: String = "Yards"

    // Weekly rhythm
    @State private var targetSessions: Int = 4
    @State private var targetYards: Int = 12000

    private let swimmerTypes = [
        "College swimmer",
        "High school",
        "Club",
        "Masters",
        "Other"
    ]

    private let primaryFocusOptions = [
        "Sprint",
        "Mid-distance",
        "Distance",
        "IM / Medley"
    ]

    private let poolUnits = [
        "Yards",
        "Meters"
    ]

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            content
                .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            splashView
        case 1:
            featureTourView
        case 2:
            profileView
        default:
            weeklyRhythmView
        }
    }
}

// MARK: - Step 0: Splash & value prop

private extension OnboardingFlowView {
    var splashView: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(AppColor.accent)

                Text("SwimSetTracker")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColor.accent)

                Text("Turn your swim practices into a clean, searchable training journal.")
                    .font(AppFont.body)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut) {
                        step = 1
                    }
                } label: {
                    Text("Get started")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

// MARK: - Step 1: Feature tour

private extension OnboardingFlowView {
    var featureTourView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to SwimSetTracker")
                        .font(AppFont.pageTitle)
                        .foregroundStyle(.white)

                    Text("Here’s a quick look at what you can do.")
                        .font(AppFont.body)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                Button("Skip") {
                    withAnimation(.easeInOut) {
                        step = 2
                    }
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .buttonStyle(.plain)
            }

            TabView(selection: $featurePage) {
                featureCard(
                    title: "Scan your coach’s set",
                    subtitle: "Take a photo of the whiteboard or printout and we’ll turn it into a structured practice.",
                    systemImage: "camera.viewfinder",
                    bullets: [
                        "Works with board photos and printed sheets.",
                        "Auto-splits warmup, main set, and more.",
                        "Saves everything to your training log."
                    ]
                )
                .tag(0)

                featureCard(
                    title: "See your week at a glance",
                    subtitle: "Every practice you log shows up in your weekly view so you can see volume and rhythm.",
                    systemImage: "calendar",
                    bullets: [
                        "Total yards and sessions per week.",
                        "Easy access to each day’s practice.",
                        "Consistent Monday–Sunday layout."
                    ]
                )
                .tag(1)

                featureCard(
                    title: "Track progress, not just numbers",
                    subtitle: "Watch your stroke mix, volume, and goals evolve over time, with coaching tips for recovery.",
                    systemImage: "chart.bar.fill",
                    bullets: [
                        "Stroke breakdown for each practice.",
                        "Weekly yardage and pace trends.",
                        "Recovery ideas based on your sets."
                    ]
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 260)

            Spacer()

            Button {
                withAnimation(.easeInOut) {
                    step = 2
                }
            } label: {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer(minLength: 24)
        }
    }

    func featureCard(
        title: String,
        subtitle: String,
        systemImage: String,
        bullets: [String]
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {

                // Icon + title + main sentence (no awkward circle)
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColor.accent)
                        .frame(width: 24)   // keeps alignment consistent

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppFont.cardTitle)
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(AppFont.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                // Bullets: clear “what you get”
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(bullets, id: \.self) { item in
                        bulletRow(item)
                    }
                }

                Spacer(minLength: 4)
            }
        }
    }


    @ViewBuilder
    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(AppColor.accent)
                .padding(.top, 1)

            Text(text)
                .font(AppFont.caption)
                .foregroundStyle(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

}

// MARK: - Step 2: Swim profile

private extension OnboardingFlowView {
    var profileView: some View {
        VStack(spacing: 0) {
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Top copy
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Step 1 of 2")
                            .font(AppFont.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))

                        Text("Tell us about your training")
                            .font(AppFont.pageTitle)
                            .foregroundStyle(.white)

                        Text("This helps tailor your weekly overview, copy, and default goals.")
                            .font(AppFont.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)

                    // “Who is this journal for?” (multi-select)
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Who is this journal for?")
                                .font(AppFont.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))

                            Text("Pick all that apply so we can tune goals and language.")
                                .font(AppFont.caption)
                                .foregroundStyle(.white.opacity(0.7))

                            // Use a FlowLayout or just VStack for chips if we want them wrapping.
                            // For now, keeping vertical stack as per original design but using new Chip style.
                            // Actually, prompt asked for "Selectable Chips" for "You are a..." list.
                            // Let's use a wrapping layout or just a vertical list of chips.
                            // Given the list length, vertical stack of chips is fine.
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(swimmerTypes, id: \.self) { type in
                                    SelectableChip(
                                        label: type,
                                        isSelected: selectedSwimmerTypes.contains(type)
                                    ) {
                                        toggleSwimmerType(type)
                                    }
                                }
                            }
                        }
                    }

                    // Focus (single-select)
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Primary focus")
                                .font(AppFont.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))

                            Text("Choose the training focus that best matches most of your sessions.")
                                .font(AppFont.caption)
                                .foregroundStyle(.white.opacity(0.7))

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(primaryFocusOptions, id: \.self) { item in
                                    SelectableChip(
                                        label: item,
                                        isSelected: primaryFocus == item
                                    ) {
                                        primaryFocus = item
                                    }
                                }
                            }
                        }
                    }

                    // Pool units (single-select)
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pool units")
                                .font(AppFont.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))

                            Text("We’ll use this so your yardage and pace trends stay consistent.")
                                .font(AppFont.caption)
                                .foregroundStyle(.white.opacity(0.7))

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(poolUnits, id: \.self) { unit in
                                    SelectableChip(
                                        label: unit,
                                        isSelected: poolUnit == unit
                                    ) {
                                        poolUnit = unit
                                    }
                                }
                            }
                        }
                    }

                    // Bottom spacer so last card isn't covered by footer
                    Spacer(minLength: 24)
                }
            }

            // Pinned footer buttons
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut) {
                        step = 1   // back to feature tour
                    }
                } label: {
                    Text("Back")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    withAnimation(.easeInOut) {
                        step = 3   // forward to weekly rhythm
                    }
                } label: {
                    Text("Next")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
            .background(
                AppColor.background
                    .opacity(0.95)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    func toggleSwimmerType(_ type: String) {
        if selectedSwimmerTypes.contains(type) {
            selectedSwimmerTypes.remove(type)
        } else {
            selectedSwimmerTypes.insert(type)
        }

        // Keep a primary swimmerType string for compatibility
        if let first = selectedSwimmerTypes.first {
            swimmerType = first
        } else {
            swimmerType = type
        }
    }
}

// MARK: - Step 3: Weekly rhythm

private extension OnboardingFlowView {
    var weeklyRhythmView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 6) {
                Text("Step 2 of 2")
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))

                Text("What does a good week look like?")
                    .font(AppFont.pageTitle)
                    .foregroundStyle(.white)

                Text("We’ll use this to shape your weekly goal and pacing hints.")
                    .font(AppFont.body)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sessions per week")
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))

                    Stepper(value: $targetSessions, in: 1...14) {
                        Text("\(targetSessions) session\(targetSessions == 1 ? "" : "s")")
                            .font(AppFont.body.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Target yards per week")
                        .font(AppFont.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))

                    Stepper(value: $targetYards, in: 1000...60000, step: 500) {
                        Text("\(targetYards) yds")
                            .font(AppFont.body.weight(.semibold))
                            .foregroundStyle(.white)
                    }

                    Text("You can tweak this anytime from the Weekly Goal card.")
                        .font(AppFont.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer()

            VStack(spacing: 12) {
                // Skip button
                Button {
                    completeOnboarding()
                } label: {
                    Text("Don’t know yet? Skip for now")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.vertical, 4)
                }

                // Back / Finish
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut) {
                            step = 2   // back to profile
                        }
                    } label: {
                        Text("Back")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Finish setup")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(.bottom, 24)
        }
    }

    func completeOnboarding() {
        // Persist preferences for later use
        UserDefaults.standard.set(swimmerType, forKey: "profile_swimmerType")
        UserDefaults.standard.set(Array(selectedSwimmerTypes), forKey: "profile_swimmerTypes")
        UserDefaults.standard.set(primaryFocus, forKey: "profile_primaryFocus")
        UserDefaults.standard.set(poolUnit, forKey: "profile_poolUnit")
        UserDefaults.standard.set(targetSessions, forKey: "profile_targetSessions")
        UserDefaults.standard.set(targetYards, forKey: "profile_targetYards")

        onFinished()
    }
}

// MARK: - Shared UI helpers

// Private components removed to use global DesignSystem components

