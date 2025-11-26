import Foundation

enum BlockType: String, Codable, CaseIterable { case warmup, preset, mainset, cooldown }
enum Stroke: String, Codable, CaseIterable { case free, back, breast, fly, drill, kick, im }
enum Intensity: String, Codable, CaseIterable { case easy, aerobic, threshold, sprint }

struct SetItem: Identifiable, Codable {
    var id = UUID()
    var description: String
    var yards: Int
    var stroke: Stroke
    var intensity: Intensity
}

struct Block: Identifiable, Codable {
    var id = UUID()
    var type: BlockType
    var yards: Int { sets.reduce(0) { $0 + $1.yards } }
    var sets: [SetItem]
}

struct Practice: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var sessionLabel: String?
    var blocks: [Block]
    var totalYards: Int { blocks.reduce(0) { $0 + $1.yards } }
}

struct WeeklySummary {
    var startOfWeek: Date
    var practices: [Practice]
    var totalYards: Int { practices.reduce(0) { $0 + $1.totalYards } }
}
