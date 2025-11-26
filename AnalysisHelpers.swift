import Foundation

/// Analyzes a practice to calculate the total yards per stroke type.
/// - Parameter practice: The analyzed practice to process.
/// - Returns: A dictionary mapping stroke names to total yards.
func strokeYardsForPractice(_ practice: AnalyzedPractice) -> [String: Int] {
    // If we have explicit stroke percentages from the analysis, use those
    if !practice.strokePercentages.isEmpty {
        var result: [String: Int] = [:]
        for (stroke, pct) in practice.strokePercentages {
            let yards = Int(Double(practice.distanceYards) * (pct / 100.0))
            result[stroke] = yards
        }
        return result
    }
    
    // Fallback: If we had detailed set data (not currently in AnalyzedPractice), we would sum it up.
    // Since AnalyzedPractice is a high-level summary, we might not have granular data if strokePercentages is empty.
    // In that case, return empty or assume Mixed/Free?
    return [:]
}
