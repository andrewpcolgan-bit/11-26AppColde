import Foundation

extension Calendar {
    static var monday: Calendar {
        var c = Calendar(identifier: .iso8601)
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }
}

struct WeeklyGoal: Codable, Equatable, Identifiable {
    var id: UUID = .init()
    var yardsTarget: Int?
    var sessionsTarget: Int?
    var startDate: Date
    var trainingPhase: TrainingPhase? = nil
    var carryForwardPhase: Bool? = nil
    var notes: String? = nil   // keep if other code still references it

    static func currentWeekInterval() -> DateInterval? {
        let cal = Calendar.monday
        guard let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start,
              let end   = cal.date(byAdding: .day, value: 7, to: start)
        else { return nil }
        return DateInterval(start: start, end: end)
    }

    enum TrainingPhase: String, CaseIterable, Codable, Identifiable {
        case base, build, speedPower, racePace, taper, recovery, technique, imFocus
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .base: return "Base Endurance"
            case .build: return "Build/Threshold"
            case .speedPower: return "Speed/Power"
            case .racePace: return "Race-Pace"
            case .taper: return "Taper/Peak"
            case .recovery: return "Recovery/Deload"
            case .technique: return "Technique"
            case .imFocus: return "IM Focus"
            }
        }
        var shortHint: String {
            switch self {
            case .base: return "Aerobic volume, moderate intensity."
            case .build: return "Threshold focus, slightly higher load."
            case .speedPower: return "Lower volume, short fast reps."
            case .racePace: return "Race-pace sets, controlled volume."
            case .taper: return "Sharp drop in volume, keep quality."
            case .recovery: return "Easy technique + light aerobic."
            case .technique: return "Drills, skills, and efficiency."
            case .imFocus: return "Balanced IM distribution."
            }
        }
        var icon: String {
            switch self {
            case .base: return "waveform.path.ecg"
            case .build: return "chart.bar.doc.horizontal"
            case .speedPower: return "bolt.fill"
            case .racePace: return "flag.checkered"
            case .taper: return "sparkles"
            case .recovery: return "bed.double.fill"
            case .technique: return "wand.and.stars"
            case .imFocus: return "square.grid.3x3.fill"
            }
        }
    }
}
