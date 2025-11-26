import SwiftUI
import Charts

struct StatsDashboardView: View {
    @EnvironmentObject var appData: AppData
    
    // Range State
    @State private var selectedRange: StatsRange = .thisWeek
    
    // Computed Range Interval
    private var currentInterval: DateInterval? {
        let cal = Calendar.current
        let now = Date()
        switch selectedRange {
        case .thisWeek:
            guard let start = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return nil }
            return DateInterval(start: start, duration: 7 * 24 * 3600)
        case .month:
            guard let start = cal.dateInterval(of: .month, for: now)?.start else { return nil }
            return DateInterval(start: start, duration: 30 * 24 * 3600) // Approx
        case .season:
            // Arbitrary season start (e.g., Aug 1st)
            var components = cal.dateComponents([.year], from: now)
            components.month = 8
            components.day = 1
            guard let start = cal.date(from: components) else { return nil }
            let actualStart = start > now ? cal.date(byAdding: .year, value: -1, to: start)! : start
            return DateInterval(start: actualStart, end: now)
        case .allTime:
            return nil // All time
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Header & Filter
                        headerSection
                        
                        // 2. Top Metrics Strip
                        metricsStrip
                        
                        // 2.5. Recovery Overview (this week only)
                        if selectedRange == .thisWeek {
                            recoveryOverviewCard
                        }
                        
                        // 3. Weekly Progress / Volume Chart
                        volumeChartCard
                        
                        // 4. Stroke Mix
                        strokeMixCard
                        
                        // 5. Cumulative Trend
                        cumulativeTrendCard
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Stats")
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - 1. Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Stats")
                    .font(AppFont.pageTitle)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Segmented Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(StatsRange.allCases) { range in
                        Button {
                            withAnimation { selectedRange = range }
                        } label: {
                            Text(range.rawValue)
                                .font(AppFont.body.weight(.medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedRange == range ? Color.appAccent.opacity(0.2) : Color.white.opacity(0.05)
                                )
                                .foregroundStyle(
                                    selectedRange == range ? Color.appAccent : Color.textSecondary
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(selectedRange == range ? Color.appAccent.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - 2. Metrics Strip
    private var metricsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                let totals = appData.totals(in: currentInterval)
                let avgYards = totals.sessions > 0 ? totals.yards / totals.sessions : 0
                
                MetricTile(label: "Total Yards", value: "\(totals.yards)", icon: "figure.pool.swim")
                    .frame(width: 140)
                
                MetricTile(label: "Sessions", value: "\(totals.sessions)", icon: "checkmark.circle")
                    .frame(width: 120)
                
                MetricTile(label: "Avg / Session", value: "\(avgYards)", icon: "ruler")
                    .frame(width: 140)
                
                // Longest Practice
                if let maxP = appData.practices(in: currentInterval).max(by: { $0.distanceYards < $1.distanceYards }) {
                    MetricTile(label: "Longest", value: "\(maxP.distanceYards)", icon: "trophy")
                        .frame(width: 120)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - 3. Volume Chart
    private var volumeChartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Yardage Over Time")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                
                let data = chartData()
                
                if data.isEmpty {
                    Text("No data for this period")
                        .font(AppFont.captionMuted)
                        .foregroundStyle(Color.textMuted)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart(data) { item in
                        BarMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Yards", item.yards)
                        )
                        .foregroundStyle(Color.appAccent.gradient)
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel(format: .dateTime.weekday(.narrow))
                                    .foregroundStyle(Color.textMuted)
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                            AxisValueLabel()
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                    .frame(height: 220)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 4. Stroke Mix
    private var strokeMixCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Stroke Mix")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                
                let mix = strokeTotals()
                let total = mix.map(\.value).reduce(0, +)
                
                if mix.isEmpty {
                    Text("No stroke data")
                        .font(AppFont.captionMuted)
                        .foregroundStyle(Color.textMuted)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                } else {
                    HStack(spacing: 20) {
                        Chart(mix, id: \.key) { item in
                            SectorMark(
                                angle: .value("Yards", item.value),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(strokeColor(for: item.key))
                        }
                        .frame(width: 120, height: 120)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(mix.sorted(by: { $0.value > $1.value }).prefix(5), id: \.key) { item in
                                HStack {
                                    Circle()
                                        .fill(strokeColor(for: item.key))
                                        .frame(width: 8, height: 8)
                                    Text(item.key.capitalized)
                                        .font(AppFont.caption)
                                        .foregroundStyle(Color.textPrimary)
                                    Spacer()
                                    Text("\(Int((item.value / total) * 100))%")
                                        .font(AppFont.captionMuted)
                                        .foregroundStyle(Color.textMuted)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 5. Cumulative Trend
    private var cumulativeTrendCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cumulative Progress")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                
                let data = cumulativeData()
                
                if data.isEmpty {
                    Text("No data")
                        .font(AppFont.captionMuted)
                        .foregroundStyle(Color.textMuted)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                } else {
                    Chart(data) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Total Yards", item.total)
                        )
                        .foregroundStyle(Color.appAccent)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Total Yards", item.total)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.3), Color.appAccent.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel(format: .dateTime.month().day())
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                            AxisValueLabel()
                                .foregroundStyle(Color.textMuted)
                        }
                    }
                    .frame(height: 200)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Recovery Overview Card
    private var recoveryOverviewCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recovery")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Color.positive)
                
                // Strain Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("This week:")
                        .font(AppFont.caption)
                        .foregroundStyle(Color.textMuted)
                    
                    HStack(spacing: 16) {
                        // High days
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red.opacity(0.8))
                                .frame(width: 8, height: 8)
                            Text("\(appData.highStrainCount) high")
                                .font(AppFont.caption)
                                .foregroundStyle(Color.textPrimary)
                        }
                        
                        // Medium days
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.yellow.opacity(0.8))
                                .frame(width: 8, height: 8)
                            Text("\(appData.mediumStrainCount) medium")
                                .font(AppFont.caption)
                                .foregroundStyle(Color.textPrimary)
                        }
                        
                        // Low days
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green.opacity(0.8))
                                .frame(width: 8, height: 8)
                            Text("\(appData.lowStrainCount) low")
                                .font(AppFont.caption)
                                .foregroundStyle(Color.textPrimary)
                        }
                    }
                }
                
                Divider().overlay(Color.white.opacity(0.1))
                
                // Recovery Completion
                VStack(alignment: .leading, spacing: 12) {
                    if appData.totalRecoveryTasks > 0 {
                        HStack {
                            Text("Recovery tasks completed:")
                                .font(AppFont.caption)
                                .foregroundStyle(Color.textMuted)
                            Spacer()
                            Text("\(appData.completedRecoveryTasks) of \(appData.totalRecoveryTasks)")
                                .font(AppFont.captionBold)
                                .foregroundStyle(Color.positive)
                        }
                        
                        ProgressView(value: appData.recoveryCompletionRate)
                            .progressViewStyle(.linear)
                            .tint(Color.positive)
                    } else {
                        Text("No recovery tasks logged yet")
                            .font(AppFont.caption)
                            .foregroundStyle(Color.textMuted)
                    }
                }
                
                Divider().overlay(Color.white.opacity(0.1))
                
                // Suggestion
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color.warning)
                        .font(.caption)
                    Text(appData.recoverySuggestion)
                        .font(AppFont.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helpers & Data
    
    struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let yards: Int
    }
    
    struct CumulativePoint: Identifiable {
        let id = UUID()
        let date: Date
        let total: Int
    }
    
    private func chartData() -> [ChartPoint] {
        let practices = appData.practices(in: currentInterval)
        
        // Explicitly group by day
        let grouped = Dictionary(grouping: practices) { (p: AnalyzedPractice) -> Date in
            let d = ISO8601DateFormatter().date(from: p.date) ?? Date()
            return Calendar.current.startOfDay(for: d)
        }
        
        // Map to ChartPoint
        let points = grouped.map { (key: Date, value: [AnalyzedPractice]) -> ChartPoint in
            let totalYards = value.reduce(0) { $0 + $1.distanceYards }
            return ChartPoint(date: key, yards: totalYards)
        }
        
        return points.sorted { $0.date < $1.date }
    }
    
    private func cumulativeData() -> [CumulativePoint] {
        let practices = appData.practices(in: currentInterval).sorted { $0.date < $1.date }
        var points: [CumulativePoint] = []
        var runningTotal = 0
        
        for p in practices {
            runningTotal += p.distanceYards
            if let date = ISO8601DateFormatter().date(from: p.date) {
                points.append(CumulativePoint(date: date, total: runningTotal))
            }
        }
        return points
    }
    
    private func strokeTotals() -> [(key: String, value: Double)] {
        let practices = appData.practices(in: currentInterval)
        var totals: [String: Double] = [:]
        
        for p in practices {
            for (stroke, yards) in strokeYardsForPractice(p) {
                totals[stroke, default: 0] += Double(yards)
            }
        }
        return totals.map { ($0.key, $0.value) }.sorted { $0.value > $1.value }
    }
    
    private func strokeColor(for stroke: String) -> Color {
        let s = stroke.lowercased()
        if s.contains("free") { return Color.appAccent }
        if s.contains("back") { return Color.blue }
        if s.contains("breast") { return Color.green }
        if s.contains("fly") || s.contains("butter") { return Color.purple }
        if s.contains("im") { return Color.indigo }
        if s.contains("kick") { return Color.yellow }
        if s.contains("drill") { return Color.gray }
        return Color.white.opacity(0.3)
    }
}

// Helper Enum
enum StatsRange: String, CaseIterable, Identifiable {
    case thisWeek = "Week"
    case month = "Month"
    case season = "Season"
    case allTime = "All Time"
    var id: String { rawValue }
}

// Helper extension for AppData to get practices in range (if not already present)

