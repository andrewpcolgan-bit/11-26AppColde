//
//  PracticeListView.swift
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - PracticeListView

// MARK: - PracticeListView

// MARK: - PracticeListView

struct PracticeListView: View {
    @EnvironmentObject var appData: AppData

    // Search
    @State private var searchText = ""

    // Filters
    @State private var datePreset: DatePreset = .all
    @State private var selectedAMPM: AMPMFilter = .any
    @State private var typeFilters: Set<TypeToken> = []
    @State private var yardageMin: Int? = nil
    @State private var hasPDFOnly = false

    // Sorting
    @State private var sortOrder: SortOrder = .newest

    // Share
    @State private var shareURL: URL? = nil
    @State private var showingShare = false

    var body: some View {
        ZStack {
            // Global Background
            AppColor.background
                .ignoresSafeArea()
            
            // Background Gradient
            LinearGradient(colors: [
                AppColor.background,
                AppColor.surface.opacity(0.5)
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 16) {
                        headerSummary
                        filterChipsRow
                        sortBar
                        inlineSearchBar
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 10)

                    // Grouped results
                    ForEach(groupedByMonth.keys.sorted(by: >), id: \.self) { monthKey in
                        if let bucket = groupedByMonth[monthKey] {
                            Section {
                                ForEach(bucket) { p in
                                    let url = appData.pdfURL(for: p.id)
                                    let hasPDFFlag = FileManager.default.fileExists(atPath: url.path)

                                    NavigationLink {
                                        PracticeDetailScreen(practice: p)
                                            .environmentObject(appData)
                                    } label: {
                                        PastPracticeRow(
                                            practice: p,
                                            pdfURL: hasPDFFlag ? url : nil,
                                            hasPDF: hasPDFFlag,
                                            share: { shareURL in
                                                self.shareURL = shareURL
                                                self.showingShare = true
                                            }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle()) // Remove default list selection style
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            appData.deletePractice(p)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(AppColor.danger)
                                        
                                        if hasPDFFlag {
                                            Button {
                                                shareURL = url
                                                showingShare = true
                                            } label: {
                                                Label("Share PDF", systemImage: "square.and.arrow.up")
                                            }
                                            .tint(AppColor.accent)
                                        }
                                    }
                                }
                            } header: {
                                Text(monthKey)
                                    .font(AppFont.pageTitle)
                                    .foregroundStyle(.white)
                                    .padding(.top, 12)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    if filteredSortedPractices.isEmpty {
                        GlassCard {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundStyle(AppColor.accentSecondary)
                                Text("No practices logged yet")
                                    .font(AppFont.cardTitle)
                                    .foregroundStyle(.white)
                                Text("Tap ‘Log New Practice’ in the Log tab to get started.")
                                    .font(AppFont.body)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
                .padding(.bottom, 100) // Bottom padding for scroll
            }
        }
        .navigationTitle("Past Practices")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingShare) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - Header summary (more compact)

    private var headerSummary: some View {
        let rows = filteredSortedPractices
        let totalYards = rows.reduce(0) { $0 + $1.distanceYards }
        let totalMins = rows.reduce(0) { $0 + max(0, $1.durationMinutes) }

        return VStack(alignment: .leading, spacing: 6) {
            Text("\(rows.count) practices • \(totalYards.formatted(.number.grouping(.automatic))) yds • \(formatTotalMinutes(totalMins))")
                .font(AppFont.body)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Filter chips

    private var filterChipsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Row 1: Date presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DatePreset.allCases, id: \.self) { preset in
                        Chip(text: preset.label, isActive: datePreset == preset) {
                            datePreset = preset
                        }
                    }
                    Chip(icon: "doc.text.fill", text: "Has PDF", isActive: hasPDFOnly) {
                        hasPDFOnly.toggle()
                    }
                }
                .padding(.vertical, 2)
            }

            // Row 2: AM/PM + type
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AMPMFilter.allCases, id: \.self) { f in
                        Chip(text: f.label, isActive: selectedAMPM == f) {
                            selectedAMPM = f
                        }
                    }

                    ForEach(TypeToken.allCases, id: \.self) { token in
                        Chip(text: token.label, isActive: typeFilters.contains(token)) {
                            if typeFilters.contains(token) { typeFilters.remove(token) }
                            else { typeFilters.insert(token) }
                        }
                    }

                    Chip(text: yardageMin == nil ? "> 5k yds" : "> \(yardageMin!.formatted())",
                         isActive: yardageMin != nil) {
                        if yardageMin == nil { yardageMin = 5000 } else { yardageMin = nil }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Sort Bar

    private var sortBar: some View {
        Picker("Sort", selection: $sortOrder) {
            ForEach(SortOrder.allCases, id: \.self) { s in
                Text(s.label).tag(s)
            }
        }
        .pickerStyle(.segmented)
        .colorScheme(.dark) // Ensure segmented control looks good on dark background
    }

    // MARK: - Inline search bar (date-based search)

    private var inlineSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.7))
                .font(.system(size: 18, weight: .medium))

            TextField("", text: $searchText)
                .font(AppFont.body)
                .foregroundStyle(.white)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .placeholder(when: searchText.isEmpty) {
                    Text("Search by date…").foregroundColor(.white.opacity(0.5))
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Data pipelines

    private var filteredSortedPractices: [AnalyzedPractice] {
        let base = appData.loggedPractices

        // Search: by date text only
        let searched: [AnalyzedPractice]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searched = base
        } else {
            let q = searchText.lowercased()
            searched = base.filter { p in
                let hay = searchableDateString(for: p)
                return hay.contains(q)
            }
        }

        // Date preset filter
        let now = Date()
        let filteredByDate = searched.filter { p in
            guard let d = ISO8601DateFormatter().date(from: p.date) else { return true }
            switch datePreset {
            case .all: return true
            case .last7:
                return d >= Calendar.current.date(byAdding: .day, value: -7, to: now)!
            case .last30:
                return d >= Calendar.current.date(byAdding: .day, value: -30, to: now)!
            case .thisSeason:
                let seasonStart = seasonStartDate(reference: now)
                return d >= seasonStart
            }
        }

        // AM/PM filter
        let filteredByAMPM = filteredByDate.filter { p in
            switch selectedAMPM {
            case .any: return true
            case .am: return ampm(for: p) == "AM"
            case .pm: return ampm(for: p) == "PM"
            }
        }

        // Type filters (tokens)
        let filteredByType: [AnalyzedPractice]
        if typeFilters.isEmpty {
            filteredByType = filteredByAMPM
        } else {
            filteredByType = filteredByAMPM.filter { p in
                let tag = ((p.practiceTag ?? "") + " " + p.aiSummary).lowercased()
                return typeFilters.contains { $0.matches(in: tag) }
            }
        }

        // Yardage threshold
        let filteredByYards = filteredByType.filter { p in
            if let min = yardageMin { return p.distanceYards >= min }
            return true
        }

        // Has PDF
        let filteredByPDF = filteredByYards.filter { p in
            let url = appData.pdfURL(for: p.id)
            return hasPDFOnly ? FileManager.default.fileExists(atPath: url.path) : true
        }

        // Sort
        return filteredByPDF.sorted(by: sortOrder.compare)
    }

    private var groupedByMonth: [String: [AnalyzedPractice]] {
        Dictionary(grouping: filteredSortedPractices) { p in
            guard let d = ISO8601DateFormatter().date(from: p.date) else { return "Unknown" }
            let f = DateFormatter()
            f.dateFormat = "LLLL yyyy" // "November 2025"
            return f.string(from: d)
        }
    }

    // MARK: - Small helpers

    private func searchableDateString(for p: AnalyzedPractice) -> String {
        // Build a big lowercase date string so user can type "nov", "11/16", "2025", etc.
        guard let d = ISO8601DateFormatter().date(from: p.date) else {
            return p.date.lowercased()
        }

        let named = DateFormatter()
        named.locale = Locale(identifier: "en_US_POSIX")
        named.dateFormat = "EEEE MMM d yyyy" // "Sunday Nov 16 2025"

        let numeric = DateFormatter()
        numeric.locale = Locale(identifier: "en_US_POSIX")
        numeric.dateFormat = "M/d/yyyy"      // "11/16/2025"

        return (named.string(from: d) + " " + numeric.string(from: d)).lowercased()
    }

    private func seasonStartDate(reference: Date) -> Date {
        // Define season as Aug 1 -> Jul 31
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: reference)
        let year = comps.year ?? 2025
        if (comps.month ?? 1) >= 8 {
            return cal.date(from: DateComponents(year: year, month: 8, day: 1))!
        } else {
            return cal.date(from: DateComponents(year: year - 1, month: 8, day: 1))!
        }
    }

    private func ampm(for p: AnalyzedPractice) -> String? {
        switch (p.timeOfDay ?? "").uppercased() {
        case "AM", "MORNING": return "AM"
        case "PM", "AFTERNOON", "EVENING": return "PM"
        default:
            if let date = ISO8601DateFormatter().date(from: p.date) {
                let hour = Calendar.current.component(.hour, from: date)
                return hour < 12 ? "AM" : "PM"
            }
            return nil
        }
    }

    private func formatTotalMinutes(_ minutes: Int) -> String {
        guard minutes > 0 else { return "0m" }
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

// MARK: - Row View

private struct PastPracticeRow: View {
    let practice: AnalyzedPractice
    let pdfURL: URL?
    let hasPDF: Bool
    let share: (URL) -> Void

    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                // Top Row: Date/Tag | Metrics
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(dateSmall(for: practice))
                            .font(AppFont.body.weight(.semibold))
                            .foregroundStyle(.white)
                        
                        SelectableChip(
                            label: titleCasedTag(from: practice),
                            isSelected: true, // Always "selected" style for visibility
                            action: {} // Non-interactive
                        )
                        .disabled(true)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        // Yardage
                        Text(practice.distanceYards.formatted(.number.grouping(.automatic)))
                            .font(AppFont.metricLarge)
                            .foregroundStyle(AppColor.accent)
                        
                        // Duration
                        Text(formatTotalMinutes(practice.durationMinutes))
                            .font(AppFont.body)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        // Strain & Recovery Indicators
                        HStack(spacing: 8) {
                            // Strain badge
                            if let strain = practice.insights?.strainCategory?.lowercased() {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(strainColor(for: strain))
                                        .frame(width: 6, height: 6)
                                    Text(strain.capitalized)
                                        .font(AppFont.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            
                            // Recovery indicator
                            if let plan = practice.recoveryPlan, !plan.tasks.isEmpty {
                                let completed = plan.tasks.filter { $0.isCompleted }.count
                                let total = plan.tasks.count
                                
                                HStack(spacing: 4) {
                                    Image(systemName: recoveryIcon(completed: completed, total: total))
                                        .font(.caption2)
                                        .foregroundStyle(Color.positive)
                                    Text("\(completed)/\(total)")
                                        .font(AppFont.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                        }
                    }
                }
                
                // Divider
                AccentDivider()
                    .opacity(0.3)
                
                // Section Breakdown
                VStack(spacing: 6) {
                    sectionRow(label: "Warmup", yards: practice.sectionYards["Warmup"])
                    sectionRow(label: "Pre-Set", yards: practice.sectionYards["Preset"])
                    sectionRow(label: "Main Set", yards: practice.sectionYards["Main Set"])
                    sectionRow(label: "Post-Set", yards: practice.sectionYards["Post-Set"])
                    sectionRow(label: "Cooldown", yards: practice.sectionYards["Cooldown"])
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func sectionRow(label: String, yards: Int?) -> some View {
        if let y = yards, y > 0 {
            HStack {
                Text(label)
                    .font(AppFont.captionMuted)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("\(y) yds")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    // MARK: helpers (row)

    private func dateSmall(for p: AnalyzedPractice) -> String {
        guard let d = ISO8601DateFormatter().date(from: p.date) else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "E, MMM d"
        return f.string(from: d)
    }

    private func titleCasedTag(from p: AnalyzedPractice) -> String {
        let raw = (p.practiceTag?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
            ?? "Unlabeled"
        // Simple capitalization
        return raw.capitalized
    }

    private func formatTotalMinutes(_ minutes: Int) -> String {
        guard minutes > 0 else { return "0m" }
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return String(m) + "m"
    }
    
    private func strainColor(for strain: String) -> Color {
        switch strain {
        case "high": return Color.red.opacity(0.8)
        case "medium", "moderate": return Color.yellow.opacity(0.8)
        case "low": return Color.green.opacity(0.8)
        default: return Color.white.opacity(0.5)
        }
    }
    
    private func recoveryIcon(completed: Int, total: Int) -> String {
        let rate = Double(completed) / Double(total)
        if rate >= 0.8 { return "checkmark.circle.fill" }
        if rate > 0 { return "circle.lefthalf.filled" }
        return "circle"
    }
}

// MARK: - Chips + enums

private struct Chip: View {
    var icon: String? = nil
    let text: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(text)
                    .font(AppFont.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? AppColor.accent.opacity(0.2) : AppColor.surface)
                    .overlay(
                        Capsule()
                            .stroke(isActive ? AppColor.accent : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? AppColor.accent : .white.opacity(0.7))
    }
}

private enum DatePreset: CaseIterable {
    case all, last7, last30, thisSeason
    var label: String {
        switch self {
        case .all: return "All"
        case .last7: return "Last 7d"
        case .last30: return "Last 30d"
        case .thisSeason: return "This Season"
        }
    }
}

private enum AMPMFilter: CaseIterable {
    case any, am, pm
    var label: String {
        switch self {
        case .any: return "Any"
        case .am: return "AM"
        case .pm: return "PM"
        }
    }
}

private enum TypeToken: CaseIterable, Hashable {
    case im, midDistance, sprint, threshold, aerobic, kick, pull
    var label: String {
        switch self {
        case .im: return "IM"
        case .midDistance: return "Mid-Distance"
        case .sprint: return "Sprint"
        case .threshold: return "Threshold"
        case .aerobic: return "Aerobic"
        case .kick: return "Kick"
        case .pull: return "Pull"
        }
    }
    func matches(in lowercasedText: String) -> Bool {
        switch self {
        case .im: return lowercasedText.contains(" im ")
            || lowercasedText.hasPrefix("im ")
            || lowercasedText.contains(" im-")
            || lowercasedText.contains(" individual medley")
        case .midDistance: return lowercasedText.contains("mid") && lowercasedText.contains("distance")
        case .sprint: return lowercasedText.contains("sprint") || lowercasedText.contains("race-pace") || lowercasedText.contains("race pace")
        case .threshold: return lowercasedText.contains("threshold")
        case .aerobic: return lowercasedText.contains("aerobic")
        case .kick: return lowercasedText.contains("kick")
        case .pull: return lowercasedText.contains("pull")
        }
    }
}

private enum SortOrder: CaseIterable {
    case newest, oldest, mostYards, longest

    var label: String {
        switch self {
        case .newest: return "Newest"
        case .oldest: return "Oldest"
        case .mostYards: return "Most yds"
        case .longest: return "Longest"
        }
    }

    func compare(_ a: AnalyzedPractice, _ b: AnalyzedPractice) -> Bool {
        let aDate = ISO8601DateFormatter().date(from: a.date)
        let bDate = ISO8601DateFormatter().date(from: b.date)

        switch self {
        case .newest:
            return (aDate ?? .distantPast) > (bDate ?? .distantPast)
        case .oldest:
            return (aDate ?? .distantFuture) < (bDate ?? .distantFuture)
        case .mostYards:
            return a.distanceYards > b.distanceYards
        case .longest:
            return (a.durationMinutes) > (b.durationMinutes)
        }
    }
}


