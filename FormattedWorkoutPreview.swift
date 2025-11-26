import Foundation

/// Preview data structure for formatted workout before applying to builder
struct FormattedWorkoutPreview {
    let updatedPractice: BuiltPracticeTemplate
    let response: FormatWorkoutResponseDTO
    let totalYards: Int
    let totalSets: Int
}
