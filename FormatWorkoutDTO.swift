import Foundation

// MARK: - Enums

enum SectionNameDTO: String, Codable {
    case warmup
    case preset
    case main
    case postset
    case cooldown
    case unknown
}

enum IntervalKindDTO: String, Codable {
    case sendoff
    case rest
    case none
}

enum StrokeDTO: String, Codable {
    case free
    case back
    case breast
    case fly
    case im
    case choice
    case mixed
}

enum ModeDTO: String, Codable {
    case swim
    case kick
    case pull
    case drill
    case scull
    case technique
}

// MARK: - Nested Structures

struct IntervalDTO: Codable {
    var kind: IntervalKindDTO
    var seconds: Int?
}

struct PatternDTO: Codable {
    var type: String
    var start: Int?
    var end: Int?
    var raw: String?
}

// MARK: - Main Response Types

struct FormattedBlockDTO: Codable {
    var displayText: String
    var section: SectionNameDTO
    var reps: Int
    var distance: Int?
    var stroke: StrokeDTO?
    var mode: ModeDTO?
    var interval: IntervalDTO
    var pattern: PatternDTO?
    var equipment: [String]
    var notes: String
}

struct FormattedSectionDTO: Codable, Identifiable {
    var name: SectionNameDTO
    var title: String
    var blocks: [FormattedBlockDTO]
    
    var id: String { name.rawValue }
}

struct FormatIssueDTO: Codable, Identifiable {
    var lineNumber: Int
    var lineText: String
    var reason: String
    
    var id: Int { lineNumber }
}

struct FormatWorkoutResponseDTO: Codable {
    var sections: [FormattedSectionDTO]
    var issues: [FormatIssueDTO]
    var normalizedText: String
}
