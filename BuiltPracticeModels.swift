import Foundation

struct BuiltPracticeTemplate: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String                  // e.g. "Monday AM Sprinters"
    var notes: String?                 // e.g. "Team Practice", "IM Mid Distance"
    // defaultInterval removed
    var poolInfo: String?              // e.g. "25 Yards"
    var tag: PracticeTag?              // e.g. .sprint, .distance
    
    var sections: [PracticeSection]    // ordered sections: Warmup, Pre-Set, Main Set, etc.
    var rawText: String?               // Text mode input - stores original typed workout

    var createdAt: Date
    var lastEditedAt: Date
    
    // Custom decoding for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        poolInfo = try container.decodeIfPresent(String.self, forKey: .poolInfo)
        
        // Try decoding tag as PracticeTag first
        if let tagValue = try? container.decodeIfPresent(PracticeTag.self, forKey: .tag) {
            tag = tagValue
        } else if let stringTag = try? container.decodeIfPresent(String.self, forKey: .tag) {
            // Fallback: try to map string to enum
            tag = PracticeTag(rawValue: stringTag) ?? PracticeTag(from: stringTag)
        } else {
            tag = nil
        }
        
        sections = try container.decode(Array<PracticeSection>.self, forKey: .sections)
        rawText = try container.decodeIfPresent(String.self, forKey: .rawText)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastEditedAt = try container.decode(Date.self, forKey: .lastEditedAt)
    }
    
    // Default init
    init(id: UUID, title: String, notes: String?, poolInfo: String?, tag: PracticeTag?, sections: [PracticeSection], rawText: String? = nil, createdAt: Date, lastEditedAt: Date) {
        self.id = id
        self.title = title
        self.notes = notes
        self.poolInfo = poolInfo
        self.tag = tag
        self.sections = sections
        self.rawText = rawText
        self.createdAt = createdAt
        self.lastEditedAt = lastEditedAt
    }
}

enum PracticeTag: String, Codable, CaseIterable, Identifiable, Hashable {
    case sprint = "Sprint"
    case distance = "Distance"
    case im = "IM"
    case recovery = "Recovery"
    case threshold = "Threshold"
    case skills = "Skills"
    
    var id: String { rawValue }
    
    // Helper to map from old string values if they differ slightly
    init?(from string: String) {
        // Simple case-insensitive match
        let lower = string.lowercased()
        if lower.contains("sprint") { self = .sprint }
        else if lower.contains("distance") { self = .distance }
        else if lower.contains("im") { self = .im }
        else if lower.contains("recovery") { self = .recovery }
        else if lower.contains("threshold") { self = .threshold }
        else if lower.contains("skills") || lower.contains("drill") { self = .skills }
        else { return nil }
    }
}

struct PracticeSection: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var label: String                  // "Warmup", "Pre-Set", "Main Set", "Kick", "Technique & Recovery", "Cooldown"
    var sets: [PracticeSet]
}

struct PracticeSet: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String?                 // "Kick", "Technique & Recovery"
    var repeatCount: Int               // Default 1
    var lines: [PracticeLine]
    // patterns removed from Set level
    
    init(id: UUID = UUID(), title: String? = nil, repeatCount: Int = 1, lines: [PracticeLine] = []) {
        self.id = id
        self.title = title
        self.repeatCount = repeatCount
        self.lines = lines
    }
}

// MARK: - Pattern Models

enum PacePattern: String, Codable, CaseIterable, Identifiable {
    case easy
    case cruise
    case moderate
    case fast
    case sprint
    case descend
    case ascend
    case build
    case negativeSplit
    case evenPace
    case bestAverage
    case holdPace
    case racePace
    case threshold

    var id: String { rawValue }

    var label: String {
        switch self {
        case .easy: return "Easy (EZ)"
        case .cruise: return "Cruise"
        case .moderate: return "Moderate / Strong"
        case .fast: return "Fast"
        case .sprint: return "Sprint / All-out"
        case .descend: return "Descend"
        case .ascend: return "Ascend"
        case .build: return "Build"
        case .negativeSplit: return "Negative split"
        case .evenPace: return "Even pace"
        case .bestAverage: return "Best average"
        case .holdPace: return "Hold pace"
        case .racePace: return "Race pace"
        case .threshold: return "Threshold"
        }
    }

    /// Short code that can appear in PDF text.
    var code: String {
        switch self {
        case .easy: return "EZ"
        case .cruise: return "Cruise"
        case .moderate: return "Mod"
        case .fast: return "Fast"
        case .sprint: return "Sp"
        case .descend: return "DESC"
        case .ascend: return "ASC"
        case .build: return "Bld"
        case .negativeSplit: return "N/S"
        case .evenPace: return "Even"
        case .bestAverage: return "Best avg"
        case .holdPace: return "Hold"
        case .racePace: return "Race pace"
        case .threshold: return "Threshold"
        }
    }

    /// Default English description to seed line text if empty.
    var defaultDescription: String {
        switch self {
        case .easy: return "easy, long strokes"
        case .cruise: return "cruise pace, relaxed but controlled"
        case .moderate: return "moderate to strong effort"
        case .fast: return "fast but not all-out"
        case .sprint: return "all-out sprint"
        case .descend: return "descend each repeat"
        case .ascend: return "ascend each repeat"
        case .build: return "build within each repeat, finish strong"
        case .negativeSplit: return "negative split second half faster"
        case .evenPace: return "hold even pace"
        case .bestAverage: return "best average, keep times tight"
        case .holdPace: return "hold target pace"
        case .racePace: return "race pace work"
        case .threshold: return "threshold effort, hard but sustainable"
        }
    }
}

enum StrokePattern: String, Codable, CaseIterable, Identifiable {
    case choice
    case imo
    case rimo
    case strokeFree
    case frim
    case drillSwim
    case kickSwim
    case pull

    var id: String { rawValue }

    var label: String {
        switch self {
        case .choice: return "Choice"
        case .imo: return "IM order (IMO)"
        case .rimo: return "Reverse IM (RIMO)"
        case .strokeFree: return "Stroke / Free"
        case .frim: return "FRIM"
        case .drillSwim: return "Drill / Swim"
        case .kickSwim: return "Kick / Swim"
        case .pull: return "Pull"
        }
    }

    var defaultDescription: String {
        switch self {
        case .choice: return "choice stroke"
        case .imo: return "IM order"
        case .rimo: return "reverse IM order"
        case .strokeFree: return "stroke/free mix"
        case .frim: return "free / IM combo"
        case .drillSwim: return "drill/swim by 25 or 50"
        case .kickSwim: return "kick/swim mix"
        case .pull: return "pull focus"
        }
    }
}

enum FocusTag: String, Codable, CaseIterable, Identifiable {
    case hypoxic
    case dps
    case perfectTechnique
    case kickFocus
    case startsBreakouts

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hypoxic: return "Hypoxic"
        case .dps: return "Stroke count / DPS"
        case .perfectTechnique: return "Perfect technique"
        case .kickFocus: return "Kick focus"
        case .startsBreakouts: return "Starts & breakouts"
        }
    }

    var defaultDescription: String {
        switch self {
        case .hypoxic: return "hypoxic breathing (limited breaths / UW work)"
        case .dps: return "low stroke count, DPS focus"
        case .perfectTechnique: return "focus on perfect technique"
        case .kickFocus: return "legs & kick focused"
        case .startsBreakouts: return "focus on starts and breakouts"
        }
    }
}

struct SetPatterns: Codable, Equatable, Hashable {
    var pace: PacePattern?
    var stroke: StrokePattern?
    var focus: [FocusTag] = []
}

enum StrokeType: String, Codable, CaseIterable, Identifiable, Hashable {
    // Strokes
    case freestyle
    case backstroke
    case breaststroke
    case butterfly
    case im
    case choice
    
    // Modes
    case swim
    case kick
    case pull
    case drill
    case scull
    case technique
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .freestyle:   return "Free"
        case .backstroke:  return "Back"
        case .breaststroke:return "Breast"
        case .butterfly:   return "Fly"
        case .im:          return "IM"
        case .choice:      return "Choice"
        case .swim:        return "Swim"
        case .kick:        return "Kick"
        case .pull:        return "Pull"
        case .drill:       return "Drill"
        case .scull:       return "Scull"
        case .technique:   return "Technique"
        case .other:       return "Other"
        }
    }
    
    var isStroke: Bool {
        switch self {
        case .freestyle, .backstroke, .breaststroke, .butterfly, .im, .choice:
            return true
        default:
            return false
        }
    }
    
    var isMode: Bool {
        switch self {
        case .swim, .kick, .pull, .drill, .scull, .technique:
            return true
        default:
            return false
        }
    }
}

enum IntervalKind: String, Codable, CaseIterable, Identifiable {
    case sendoff   // "@ 1:10"
    case rest      // ":10 rest"
    case none      // no interval
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .sendoff: return "Sendoff"
        case .rest: return "Rest"
        case .none: return "None"
        }
    }
    
    var symbol: String {
        switch self {
        case .sendoff: return "@"
        case .rest: return "rest"
        case .none: return ""
        }
    }
}

enum IntervalType: String, Codable, CaseIterable, Identifiable {
    case interval
    case rest
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .interval: return "Interval"
        case .rest: return "Rest"
        }
    }
    
    var symbol: String {
        switch self {
        case .interval: return "@"
        case .rest: return "rest"
        }
    }
    
    // Convert to IntervalKind for new system
    var asIntervalKind: IntervalKind {
        switch self {
        case .interval: return .sendoff
        case .rest: return .rest
        }
    }
}

struct PracticeLine: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var reps: Int?                     // 4 from "4x50"
    var distance: Int?                 // 50 from "4x50"
    var stroke: StrokeType?            // maps to stroke percentages
    var mode: StrokeType?              // NEW: drill, kick, pull, swim, etc.
    var interval: String?              // "@ :50", "1:30", "@ 2:00" (legacy)
    var intervalType: IntervalType     // .interval or .rest (legacy)
    var intervalSeconds: Int?          // New: numeric interval in total seconds
    var intervalKind: IntervalKind     // New: sendoff/rest/none
    var text: String                   // freeform description as it should appear on the sheet
    var yardageOverride: Int?          // for weird lines, otherwise nil
    var patterns: SetPatterns          // Line-level patterns
    
    // Custom decoder for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        reps = try container.decodeIfPresent(Int.self, forKey: .reps)
        distance = try container.decodeIfPresent(Int.self, forKey: .distance)
        stroke = try container.decodeIfPresent(StrokeType.self, forKey: .stroke)
        
        // Load mode field
        let decodedMode = try container.decodeIfPresent(StrokeType.self, forKey: .mode)
        
        interval = try container.decodeIfPresent(String.self, forKey: .interval)
        intervalType = try container.decodeIfPresent(IntervalType.self, forKey: .intervalType) ?? .interval
        text = try container.decode(String.self, forKey: .text)
        yardageOverride = try container.decodeIfPresent(Int.self, forKey: .yardageOverride)
        patterns = try container.decodeIfPresent(SetPatterns.self, forKey: .patterns) ?? SetPatterns()
        
        // MIGRATION: If mode is nil (old data), try to parse it from text
        if decodedMode == nil {
            mode = Self.parseModeFromText(text)
        } else {
            mode = decodedMode
        }
        
        // New fields with migration
        if let seconds = try container.decodeIfPresent(Int.self, forKey: .intervalSeconds) {
            intervalSeconds = seconds
        } else if let legacyInterval = interval {
            intervalSeconds = Self.parseIntervalString(legacyInterval)
        } else {
            intervalSeconds = nil
        }
        
        if let kind = try container.decodeIfPresent(IntervalKind.self, forKey: .intervalKind) {
            intervalKind = kind
        } else {
            intervalKind = intervalSeconds != nil ? intervalType.asIntervalKind : .none
        }
    }
    
    // Helper to parse mode from text for migration
    private static func parseModeFromText(_ text: String) -> StrokeType? {
        let lowercase = text.lowercased()
        
        // Check for mode keywords in order of specificity
        // More specific patterns first
        if lowercase.contains("drill") {
            return .drill
        } else if lowercase.contains("kick") {
            return .kick
        } else if lowercase.contains("pull") {
            return .pull
        } else if lowercase.contains("scull") {
            return .scull
        } else if lowercase.contains("technique") {
            return .technique
        } else if lowercase.contains("swim") {
            return .swim
        }
        
        return nil
    }
    
    init(id: UUID = UUID(), reps: Int? = nil, distance: Int? = nil, stroke: StrokeType? = nil, 
         mode: StrokeType? = nil, interval: String? = nil, intervalType: IntervalType = .interval,
         intervalSeconds: Int? = nil, intervalKind: IntervalKind = .none,
         text: String = "", yardageOverride: Int? = nil, patterns: SetPatterns = SetPatterns()) {
        self.id = id
        self.reps = reps
        self.distance = distance
        self.stroke = stroke
        self.mode = mode
        self.interval = interval
        self.intervalType = intervalType
        self.intervalSeconds = intervalSeconds
        self.intervalKind = intervalKind
        self.text = text
        self.yardageOverride = yardageOverride
        self.patterns = patterns
    }
    
    private static func parseIntervalString(_ str: String) -> Int? {
        let cleaned = str.trimmingCharacters(in: .whitespaces)
        let components = cleaned.split(separator: ":")
        
        if components.count == 2 {
            let minutes = Int(components[0]) ?? 0
            let seconds = Int(components[1]) ?? 0
            return minutes * 60 + seconds
        } else if let singleValue = Int(cleaned) {
            return singleValue
        }
        return nil
    }
}

// MARK: - Helpers

extension PracticeLine {
    var computedYards: Int {
        if let yardageOverride { return yardageOverride }
        guard let distance = distance else { return 0 }
        let reps = reps ?? 1
        return distance * reps
    }
}

extension PracticeSet {
    var totalYards: Int {
        lines.reduce(0) { $0 + $1.computedYards } * repeatCount
    }
}

extension PracticeSection {
    var totalYards: Int {
        sets.reduce(0) { $0 + $1.totalYards }
    }
}

extension BuiltPracticeTemplate {
    var totalYards: Int {
        sections.reduce(0) { $0 + $1.totalYards }
    }

    func strokeYards() -> [StrokeType: Int] {
        var dict: [StrokeType: Int] = [:]
        for section in sections {
            for set in section.sets {
                let repeatCount = set.repeatCount
                for line in set.lines {
                    let yards = line.computedYards * repeatCount
                    
                    // Determine what to count based on stroke + mode combination
                    let strokeToCount: StrokeType?
                    
                    if let mode = line.mode, let stroke = line.stroke {
                        // Both stroke and mode are set
                        if mode == .swim {
                            // "Free Swim" → just count as "Freestyle"
                            strokeToCount = stroke
                        } else {
                            // "Free Drill" → count as the mode (Drill)
                            // This matches user's expectation that mode takes priority
                            strokeToCount = mode
                        }
                    } else if let mode = line.mode {
                        // Only mode set (e.g., "Kick" with no specific stroke)
                        strokeToCount = mode
                    } else if let stroke = line.stroke {
                        // Only stroke set (e.g., "Freestyle" with no mode)
                        strokeToCount = stroke
                    } else {
                        // Neither set
                        strokeToCount = nil
                    }
                    
                    if let stroke = strokeToCount {
                        dict[stroke, default: 0] += yards
                    }
                }
            }
        }
        return dict
    }
}

// MARK: - PDF Text Generation

extension BuiltPracticeTemplate {
    func commitStyleText(for date: Date, time: Date) -> String {
        var output = ""
        
        // Header
        output += "\(title)"
        if let notes = notes, !notes.isEmpty {
            output += " | \(notes)"
        }
        output += "\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E MMM d ''yy"
        let dateStr = dateFormatter.string(from: date)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeStr = timeFormatter.string(from: time)
        
        output += "\(dateStr) · \(timeStr)"
        if let poolInfo = poolInfo, !poolInfo.isEmpty {
            output += " \(poolInfo)"
        }
        output += "\n"
        
        output += "\n" // Blank line after header
        
        // Body
        for section in sections {
            // Include all sections, even if 0 yards (e.g. instructions only)
            
            output += "\(section.label)\n"
            
            for set in section.sets {
                if let title = set.title, !title.isEmpty {
                    output += "\(title)\n"
                }
                
                if set.repeatCount > 1 {
                    output += "\(set.repeatCount) rounds of:\n"
                }
                
                for line in set.lines {
                    var prefix = ""
                    if let reps = line.reps, let dist = line.distance {
                        prefix = "\(reps)x\(dist) "
                    } else if let dist = line.distance {
                        prefix = "\(dist) "
                    }
                    
                    var suffix = ""
                    if let interval = line.interval, !interval.isEmpty {
                        switch line.intervalType {
                        case .interval:
                            // If user typed "@ 1:30" manually, don't add another "@"
                            // But usually we expect just "1:30" or ":50"
                            if interval.contains("@") {
                                suffix = " \(interval)"
                            } else {
                                suffix = " @ \(interval)"
                            }
                        case .rest:
                            // "rest :15"
                            if interval.lowercased().contains("rest") {
                                suffix = " \(interval)"
                            } else {
                                suffix = " rest \(interval)"
                            }
                        }
                    }
                    
                    // Construct line text with pattern info if present
                    var lineContent = line.text
                    
                    // Append pattern codes if they aren't already part of the text (simple check)
                    var patternParts: [String] = []
                    if let pace = line.patterns.pace {
                        patternParts.append(pace.code)
                    }
                    if let stroke = line.patterns.stroke {
                        patternParts.append(stroke.label)
                    }
                    if !line.patterns.focus.isEmpty {
                        patternParts.append(line.patterns.focus.map(\.label).joined(separator: "/"))
                    }
                    
                    if !patternParts.isEmpty {
                        let patternStr = patternParts.joined(separator: " · ")
                        if lineContent.isEmpty {
                            lineContent = patternStr
                        } else {
                            lineContent += " (\(patternStr))"
                        }
                    }
                    
                    let lineStr = prefix + lineContent + suffix
                    output += "\(lineStr)\n"
                }
            }
            output += "\n" // Blank line between sections
        }
        
        return output
    }
}
