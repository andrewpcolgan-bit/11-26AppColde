import Foundation
import UIKit
import SwiftUI

@MainActor
final class AppData: ObservableObject {
    // MARK: - Document Directory Helper
    var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // MARK: - Published Properties
    @Published var loggedPractices: [AnalyzedPractice] = []
    @Published var thisWeekPractices: [AnalyzedPractice] = []
    @Published var selectedPractice: AnalyzedPractice? = nil
    @Published var recentlySavedPractice: AnalyzedPractice? = nil
    @Published var builtPracticeTemplates: [BuiltPracticeTemplate] = []
    @Published var recoveryTemplates: [RecoveryTemplate] = []

    // ✅ Weekly goal (for GoalEditorView & Weekly Goal card)
    @Published var weeklyGoal: WeeklyGoal? {
        didSet { saveWeeklyGoal() }
    }
    
    // ✅ Optional week label (e.g., "Meet Week")
    @Published var currentWeekLabel: String? = nil


    // MARK: - File Path (practices)
    var saveURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("loggedPractices.json")
    }
    
    var templatesSaveURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("builtPracticeTemplates.json")
    }
    
    var recoveryTemplatesSaveURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("recoveryTemplates.json")
    }

    // MARK: - Init
    init() {
        loadFromDisk()
        loadTemplatesFromDisk()
        loadRecoveryTemplatesFromDisk()
        loadWeeklyGoal()
        filterToCurrentWeek()
    }

    // MARK: - Save / Load (practices)
    func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(loggedPractices)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("⚠️ Failed to save practices:", error)
        }
    }

    func loadFromDisk() {
        do {
            let data = try Data(contentsOf: saveURL)
            loggedPractices = try JSONDecoder().decode([AnalyzedPractice].self, from: data)
        } catch {
            print("⚠️ No saved practices found or failed to load:", error)
            loggedPractices = []
        }
    }
    
    // MARK: - Save / Load (Templates)
    func saveTemplatesToDisk() {
        do {
            let data = try JSONEncoder().encode(builtPracticeTemplates)
            try data.write(to: templatesSaveURL, options: .atomic)
        } catch {
            print("⚠️ Failed to save templates:", error)
        }
    }

    func loadTemplatesFromDisk() {
        do {
            let data = try Data(contentsOf: templatesSaveURL)
            builtPracticeTemplates = try JSONDecoder().decode([BuiltPracticeTemplate].self, from: data)
        } catch {
            print("⚠️ No saved templates found or failed to load:", error)
            builtPracticeTemplates = []
        }
    }
    
    // MARK: - Template CRUD
    func addOrUpdateTemplate(_ template: BuiltPracticeTemplate) {
        if let idx = builtPracticeTemplates.firstIndex(where: { $0.id == template.id }) {
            builtPracticeTemplates[idx] = template
        } else {
            builtPracticeTemplates.append(template)
        }
        saveTemplatesToDisk()
    }
    
    func deleteTemplate(_ template: BuiltPracticeTemplate) {
        if let idx = builtPracticeTemplates.firstIndex(where: { $0.id == template.id }) {
            builtPracticeTemplates.remove(at: idx)
            saveTemplatesToDisk()
        }
    }
    
    // MARK: - Recovery Templates Persistence
    func saveRecoveryTemplatesToDisk() {
        do {
            let data = try JSONEncoder().encode(recoveryTemplates)
            try data.write(to: recoveryTemplatesSaveURL, options: .atomic)
        } catch {
            print("⚠️ Failed to save recovery templates:", error)
        }
    }
    
    func loadRecoveryTemplatesFromDisk() {
        do {
            let data = try Data(contentsOf: recoveryTemplatesSaveURL)
            recoveryTemplates = try JSONDecoder().decode([RecoveryTemplate].self, from: data)
        } catch {
            print("⚠️ No saved recovery templates found or failed to load:", error)
            recoveryTemplates = []
        }
    }
    
    // MARK: - Recovery Template CRUD
    func addRecoveryTemplate(_ template: RecoveryTemplate) {
        recoveryTemplates.append(template)
        saveRecoveryTemplatesToDisk()
    }
    
    func deleteRecoveryTemplate(_ template: RecoveryTemplate) {
        if let idx = recoveryTemplates.firstIndex(where: { $0.id == template.id }) {
            recoveryTemplates.remove(at: idx)
            saveRecoveryTemplatesToDisk()
        }
    }
    
    func template(by id: UUID) -> BuiltPracticeTemplate? {
        builtPracticeTemplates.first(where: { $0.id == id })
    }

    // MARK: - CRUD
    func addPractice(_ practice: AnalyzedPractice) {
        if !loggedPractices.contains(where: { $0.id == practice.id }) {
            loggedPractices.append(practice)
            saveToDisk()
            filterToCurrentWeek()
        }
    }

    func updatePractice(_ updated: AnalyzedPractice) {
        guard let idx = loggedPractices.firstIndex(where: { $0.id == updated.id }) else { return }
        loggedPractices[idx] = updated
        saveToDisk()
        filterToCurrentWeek()
    }

    func deletePractice(_ p: AnalyzedPractice) {
        if let idx = loggedPractices.firstIndex(where: { $0.id == p.id }) {
            loggedPractices.remove(at: idx)
            saveToDisk()
            filterToCurrentWeek()
        }
    }

    func clearAllPractices() {
        loggedPractices.removeAll()
        thisWeekPractices.removeAll()
        try? FileManager.default.removeItem(at: saveURL)
    }

    // MARK: - Week Filter (This Week)
    func filterToCurrentWeek() {
        let calendar = Calendar.monday
        let now = Date()

        guard
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)
        else {
            thisWeekPractices = loggedPractices
            return
        }

        let fmt = ISO8601DateFormatter()
        fmt.timeZone = .current

        thisWeekPractices = loggedPractices
            .filter { p in
                guard let d = fmt.date(from: p.date) else { return false }
                return d >= weekStart && d < weekEnd
            }
            .sorted { $0.date > $1.date }
    }
    
    // MARK: - Recovery Analytics (Current Week)
    var highStrainCount: Int {
        thisWeekPractices.filter { practice in
            practice.insights?.strainCategory?.lowercased() == "high"
        }.count
    }
    
    var mediumStrainCount: Int {
        thisWeekPractices.filter { practice in
            let strain = practice.insights?.strainCategory?.lowercased()
            return strain == "medium" || strain == "moderate" || strain == nil
        }.count
    }
    
    var lowStrainCount: Int {
        thisWeekPractices.filter { practice in
            practice.insights?.strainCategory?.lowercased() == "low"
        }.count
    }
    
    var totalRecoveryTasks: Int {
        thisWeekPractices.reduce(0) { total, practice in
            total + (practice.recoveryPlan?.tasks.count ?? 0)
        }
    }
    
    var completedRecoveryTasks: Int {
        thisWeekPractices.reduce(0) { total, practice in
            let completed = practice.recoveryPlan?.tasks.filter { $0.isCompleted }.count ?? 0
            return total + completed
        }
    }
    
    var recoveryCompletionRate: Double {
        guard totalRecoveryTasks > 0 else { return 0.0 }
        return Double(completedRecoveryTasks) / Double(totalRecoveryTasks)
    }
    
    var recoverySuggestion: String {
        // Deterministic suggestion based on strain and completion
        if highStrainCount >= 3 && recoveryCompletionRate < 0.4 {
            return "You've stacked several high days with low recovery completion. Consider a lighter day with a full recovery routine."
        } else if highStrainCount >= 2 && recoveryCompletionRate >= 0.6 {
            return "Nice job staying on top of recovery during a heavy week."
        } else if highStrainCount == 0 && thisWeekPractices.count > 0 {
            return "This week is relatively light. A key workout + recovery day could help you build momentum."
        } else if recoveryCompletionRate >= 0.8 && totalRecoveryTasks > 0 {
            return "Excellent recovery discipline! Your body will thank you."
        } else if recoveryCompletionRate < 0.3 && totalRecoveryTasks > 5 {
            return "Recovery tasks are piling up. Even 10 minutes of stretching can make a difference."
        } else {
            return "Keep balancing hard training with smart recovery."
        }
    }
}

// MARK: - “This Week” helpers (older charts)
extension AppData {
    func weeklyBuckets() -> [DayBucket] {
        let calendar = Calendar.monday
        let now = Date()
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }

        let fmt = ISO8601DateFormatter()
        fmt.timeZone = .current

        return days.map { day in
            let total = loggedPractices
                .filter {
                    if let d = fmt.date(from: $0.date) {
                        return calendar.isDate(d, inSameDayAs: day)
                    }
                    return false
                }
                .reduce(0) { $0 + $1.distanceYards }
            return DayBucket(date: day, totalYards: total)
        }
    }

    func avgSetLengthOverTime() -> [PracticePoint] {
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = .current

        return loggedPractices.compactMap { p in
            let numSections = max(1, p.sectionYards.count)
            let avg = p.distanceYards / numSections
            if let date = fmt.date(from: p.date) {
                return PracticePoint(date: date, avgYards: avg)
            }
            return nil
        }
    }

    static func funFact(for yards: Int) -> String {
        let poolLength = 50.0
        let laps = Double(yards) / poolLength
        let pools = laps / 20.0
        let formatted = String(format: "%.1f", pools)
        return "You’ve swum the length of \(formatted) Olympic pools!"
    }
}

// MARK: - Range-aware Helpers (Stats)
extension AppData {
    func practices(in interval: DateInterval?) -> [AnalyzedPractice] {
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = .current

        guard let interval else { return loggedPractices }
        return loggedPractices.filter { p in
            guard let d = fmt.date(from: p.date) else { return false }
            return interval.contains(d)
        }
    }

    func practiceCount(in interval: DateInterval?) -> Int {
        practices(in: interval).count
    }

    func totalYards(in interval: DateInterval?) -> Int {
        practices(in: interval).reduce(0) { $0 + $1.distanceYards }
    }

    func totalMinutes(in interval: DateInterval?) -> Int {
        practices(in: interval).reduce(0) { $0 + max(0, $1.durationMinutes) }
    }

    func averageYardsPerMinute(in interval: DateInterval?) -> Double {
        let totalYards = Double(totalYards(in: interval))
        let totalMinutes = Double(totalMinutes(in: interval))
        return totalMinutes > 0 ? totalYards / totalMinutes : 0
    }

    func formattedSwimTime(in interval: DateInterval?) -> String {
        let totalMinutes = totalMinutes(in: interval)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    func currentStreak() -> Int {
        let cal = Calendar.monday
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = .current

        let sortedDates = loggedPractices
            .compactMap { fmt.date(from: $0.date) }
            .sorted(by: >)

        guard let mostRecent = sortedDates.first else { return 0 }

        var streak = 1
        var currentDate = mostRecent

        for next in sortedDates.dropFirst() {
            if cal.isDate(next, inSameDayAs: currentDate) {
                continue
            } else if
                let prevDay = cal.date(byAdding: .day, value: -1, to: currentDate),
                cal.isDate(next, inSameDayAs: prevDay) {
                streak += 1
                currentDate = next
            } else {
                break
            }
        }
        return streak
    }

    func mostRecentPractice() -> AnalyzedPractice? {
        loggedPractices.max(by: { $0.date < $1.date })
    }
}

// MARK: - Goal Persistence & Progress (single source of truth)
extension AppData {
    private var weeklyGoalKey: String { "weeklyGoal.v1" }

    private func saveWeeklyGoal() {
        let defaults = UserDefaults.standard
        if let g = weeklyGoal, let data = try? JSONEncoder().encode(g) {
            defaults.set(data, forKey: weeklyGoalKey)
        } else {
            defaults.removeObject(forKey: weeklyGoalKey)
        }
    }

    private func loadWeeklyGoal() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: weeklyGoalKey),
           let g = try? JSONDecoder().decode(WeeklyGoal.self, from: data) {
            weeklyGoal = g
        } else {
            weeklyGoal = nil
        }
    }

    // Week (Mon→Sun)
    func currentWeekInterval() -> DateInterval? {
        WeeklyGoal.currentWeekInterval()
    }

    // Core totals in the current week
    func totals(in interval: DateInterval?) -> (yards: Int, sessions: Int, minutes: Int) {
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = .current

        var yards = 0
        var sessions = 0
        var minutes = 0

        for p in practices(in: interval) {
            yards += p.distanceYards
            sessions += 1
            minutes += max(0, p.durationMinutes)
        }
        return (yards, sessions, minutes)
    }

    // ✅ Weekly Goal progress used by the rings and editor
    func currentWeekGoalProgress() -> (yardsDone: Int, sessionsDone: Int) {
        let t = totals(in: currentWeekInterval())
        return (t.yards, t.sessions)
    }

    // Optional pacing hint under the rings (yards only)
    func yardsPacingHint() -> String? {
        guard let goal = weeklyGoal, let target = goal.yardsTarget,
              let week = currentWeekInterval() else { return nil }

        let now = Date()
        let elapsed = max(0, now.timeIntervalSince(week.start))
        let span = week.end.timeIntervalSince(week.start)
        let fraction = span > 0 ? max(0, min(1, elapsed / span)) : 0

        let shouldHave = Int(Double(target) * fraction)
        let have = totalYards(in: week)
        let delta = have - shouldHave

        if abs(delta) < 200 { return "On pace" }
        if delta > 0 { return "Ahead pace (~\(delta.formatted()) yds)" }
        return "Behind pace (~\((-delta).formatted()) yds)"
    }
    
    // ✅ Weekly stats helpers for Log tab
    var weekTotalYards: Int {
        totals(in: currentWeekInterval()).yards
    }
    
    var weekSessionCount: Int {
        totals(in: currentWeekInterval()).sessions
    }
    
    var weekAverageDistance: Int {
        let count = weekSessionCount
        return count > 0 ? weekTotalYards / count : 0
    }
    
    var weekTotalDuration: String {
        let minutes = totals(in: currentWeekInterval()).minutes
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Image Storage
extension AppData {
    func imageURL(for id: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("practice_\(id).jpg")
    }

    func savePracticeImage(_ image: UIImage, for id: String) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        let url = imageURL(for: id)
        do {
            try data.write(to: url)
            print("✅ Saved practice image at \(url.lastPathComponent)")
        } catch {
            print("⚠️ Failed to save practice image:", error)
        }
    }

    func imageForPractice(_ id: String) -> UIImage? {
        let url = imageURL(for: id)
        return UIImage(contentsOfFile: url.path)
    }
}

// MARK: - Practice PDF Storage
extension AppData {
    func pdfURL(for practiceID: String) -> URL {
        PracticeSheetPDFGenerator.pdfURL(for: practiceID)
    }
    func savePracticePDF(_ url: URL, for practiceID: String) {
        print("📄 PDF linked for practice:", practiceID)
    }
}

// MARK: - Supporting Models & Types
struct DayBucket: Identifiable, Equatable, Codable {
    var id: Date { date }
    var date: Date
    var totalYards: Int
    var label: String { date.formatted(.dateTime.weekday(.abbreviated)) }
}

struct PracticePoint: Identifiable, Codable {
    var id: Date { date }
    var date: Date
    var avgYards: Int
}

// Hashable conformance for navigationDestination(item:)
extension AnalyzedPractice: Hashable {
    static func == (lhs: AnalyzedPractice, rhs: AnalyzedPractice) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Calendar helper


// MARK: - Grouping Helper
struct DailyPracticeGroup: Identifiable {
    var id: Date { date }
    let date: Date
    let practices: [AnalyzedPractice]
}

extension AppData {
    func practicesGroupedByDay(from practices: [AnalyzedPractice]) -> [DailyPracticeGroup] {
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = .current
        
        let grouped = Dictionary(grouping: practices) { practice -> Date in
            guard let date = fmt.date(from: practice.date) else { return Date() }
            return Calendar.current.startOfDay(for: date)
        }
        
        return grouped.map { DailyPracticeGroup(date: $0.key, practices: $0.value) }
            .sorted { $0.date > $1.date }
    }
}
