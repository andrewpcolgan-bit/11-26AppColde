import SwiftUI

enum PatternCategory: String, Identifiable, CaseIterable {
    case pace, stroke, focus
    var id: String { rawValue }
}
