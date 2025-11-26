import SwiftUI

struct PracticeLibraryView: View {
    @EnvironmentObject var appData: AppData
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""
    @State private var selectedPractice: AnalyzedPractice? = nil

    var filteredPractices: [AnalyzedPractice] {
        let all = appData.loggedPractices.sorted { $0.date > $1.date }
        if searchText.isEmpty { return all }

        let query = searchText.lowercased()
        return all.filter { p in
            let title = practiceTitle(for: p).lowercased()
            let text = p.formattedText.lowercased()
            let summary = p.aiSummary.lowercased()
            return title.contains(query) || text.contains(query) || summary.contains(query)
        }
    }


    private var groupedByMonth: [String: [AnalyzedPractice]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return Dictionary(grouping: filteredPractices) { practice in
            if let date = ISO8601DateFormatter().date(from: practice.date) {
                return formatter.string(from: date)
            } else { return "Unknown Date" }
        }
    }

    private var monthKeys: [String] {
        groupedByMonth.keys.sorted(by: >)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if filteredPractices.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "tray")
                                .font(.system(size: 50))
                                .foregroundStyle(.gray.opacity(0.6))
                            Text("No practices saved yet")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Log a practice to start building your library.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.vertical, 80)
                    } else {
                        ForEach(monthKeys, id: \.self) { month in
                            MonthSection(month: month, practices: groupedByMonth[month] ?? [])
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Practice Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.teal)
                }
            }
            .searchable(text: $searchText, prompt: "Search practices...")
            .sheet(item: $selectedPractice) { practice in
                PracticeDetailScreen(practice: practice)
                    .environmentObject(appData)
            }
        }
    }

    // MARK: - Month Section
    private func MonthSection(month: String, practices: [AnalyzedPractice]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(month)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.leading, 6)

            Rectangle()
                .fill(Color.teal.opacity(0.4))
                .frame(height: 1)
                .padding(.bottom, 6)

            // Inside PracticeLibraryView.MonthSection(...)
            ForEach(practices) { practice in
                SwipeToDeleteCard(onDelete: {
                    appData.deletePractice(practice)
                }) {
                    // Your original button + GlassCard unchanged
                    Button {
                        selectedPractice = practice
                    } label: {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Label(practiceTitle(for: practice), systemImage: "figure.swim")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if let date = ISO8601DateFormatter().date(from: practice.date) {
                                        Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                            .font(.footnote)
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                }
                                Text("\(practice.distanceYards) yds • \(practice.durationMinutes) min")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .scale))
            }

        }
    }

    // MARK: - Practice Row
    private func PracticeRow(practice: AnalyzedPractice) -> some View {
        Button {
            selectedPractice = practice
        } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(practiceTitle(for: practice), systemImage: "figure.swim")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        if let date = ISO8601DateFormatter().date(from: practice.date) {
                            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    Text("\(practice.distanceYards) yds • \(practice.durationMinutes) min")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
            }
        }
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - Helper
    private func practiceTitle(for practice: AnalyzedPractice) -> String {
        guard let date = ISO8601DateFormatter().date(from: practice.date) else { return "Practice" }
        let weekday = date.formatted(.dateTime.weekday(.wide))
        let shortDate = date.formatted(.dateTime.month(.abbreviated).day())
        let timeLabel = practice.timeOfDay == "AM" ? "Morning Practice" : "Afternoon Practice"
        return "\(weekday) \(timeLabel) • \(shortDate)"
    }
}
