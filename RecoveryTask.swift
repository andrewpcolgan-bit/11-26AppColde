import Foundation

enum RecoveryBucket: String, Codable, CaseIterable {
    case immediate = "immediate"
    case today = "today"
    case tomorrow = "tomorrow"
    
    var displayName: String {
        switch self {
        case .immediate: return "Right after practice"
        case .today: return "Later today"
        case .tomorrow: return "Tomorrow / next session"
        }
    }
}

enum RecoveryKind: String, Codable, CaseIterable {
    case stretch = "stretch"
    case mobility = "mobility"
    case easySwim = "easy_swim"
    case activation = "activation"
    case lifestyle = "lifestyle"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .stretch: return "Stretch"
        case .mobility: return "Mobility"
        case .easySwim: return "Easy Swim"
        case .activation: return "Activation"
        case .lifestyle: return "Lifestyle"
        case .other: return "Other"
        }
    }
}

enum BodyRegion: String, Codable, CaseIterable {
    case shoulders = "shoulders"
    case legs = "legs"
    case hips = "hips"
    case core = "core"
    case fullBody = "full-body"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .shoulders: return "Shoulders"
        case .legs: return "Legs"
        case .hips: return "Hips"
        case .core: return "Core"
        case .fullBody: return "Full Body"
        case .other: return "Other"
        }
    }
}

struct RecoveryTask: Identifiable, Codable, Hashable {
    var id: UUID
    var text: String
    var bucket: RecoveryBucket
    var bodyRegion: BodyRegion
    var kind: RecoveryKind
    var includeInQuick: Bool
    var isCompleted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, text, bucket
        case bodyRegion = "body_region"
        case kind
        case includeInQuick = "include_in_quick"
        case isCompleted = "is_completed"
    }
    
    // Custom init for decoding from backend (string id -> UUID)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode id as UUID first, fall back to generating one from string
        if let uuid = try? container.decode(UUID.self, forKey: .id) {
            self.id = uuid
        } else if let stringId = try? container.decode(String.self, forKey: .id) {
            // Generate stable UUID from string
            self.id = UUID()
        } else {
            self.id = UUID()
        }
        
        self.text = try container.decode(String.self, forKey: .text)
        self.bucket = try container.decode(RecoveryBucket.self, forKey: .bucket)
        self.bodyRegion = (try? container.decode(BodyRegion.self, forKey: .bodyRegion)) ?? .other
        self.kind = (try? container.decode(RecoveryKind.self, forKey: .kind)) ?? .other
        self.includeInQuick = (try? container.decode(Bool.self, forKey: .includeInQuick)) ?? false
        self.isCompleted = (try? container.decode(Bool.self, forKey: .isCompleted)) ?? false
    }
    
    // Standard init for manual creation
    init(id: UUID = UUID(), text: String, bucket: RecoveryBucket, bodyRegion: BodyRegion = .other, kind: RecoveryKind = .other, includeInQuick: Bool = false, isCompleted: Bool = false) {
        self.id = id
        self.text = text
        self.bucket = bucket
        self.bodyRegion = bodyRegion
        self.kind = kind
        self.includeInQuick = includeInQuick
        self.isCompleted = isCompleted
    }
}

struct RecoveryPlan: Codable {
    var tasks: [RecoveryTask]
}
