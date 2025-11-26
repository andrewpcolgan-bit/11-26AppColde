import Foundation

/// Maps API DTOs from /api/formatWorkoutText to app's BuiltPractice models
enum WorkoutFormatMapper {
    
    /// Map formatted response to practice template
    static func map(
        response: FormatWorkoutResponseDTO,
        existingPractice: BuiltPracticeTemplate
    ) -> FormattedWorkoutPreview {
        
        // Map sections
        let sections: [PracticeSection] = response.sections.map { sectionDTO in
            mapSection(sectionDTO)
        }
        
        // Create updated practice
        var practice = existingPractice
        practice.sections = sections
        practice.rawText = response.normalizedText
        practice.lastEditedAt = Date()
        
        // Calculate totals
        let totalYards = sections.reduce(0) { $0 + $1.totalYards }
        let totalSets = sections.reduce(0) { sum, section in
            sum + section.sets.count
        }
        
        return FormattedWorkoutPreview(
            updatedPractice: practice,
            response: response,
            totalYards: totalYards,
            totalSets: totalSets
        )
    }
    
    // MARK: - Section Mapping
    
    private static func mapSection(_ sectionDTO: FormattedSectionDTO) -> PracticeSection {
        let sets = sectionDTO.blocks.map { blockDTO in
            mapBlock(blockDTO)
        }
        
        return PracticeSection(
            id: UUID(),
            label: sectionDTO.title,
            sets: sets
        )
    }
    
    // MARK: - Block Mapping
    
    private static func mapBlock(_ blockDTO: FormattedBlockDTO) -> PracticeSet {
        let line = PracticeLine(
            id: UUID(),
            reps: blockDTO.reps,
            distance: blockDTO.distance,
            stroke: mapStroke(blockDTO.stroke),
            interval: nil, // Legacy field, will use intervalSeconds
            intervalType: mapIntervalType(blockDTO.interval.kind),
            intervalSeconds: blockDTO.interval.seconds,
            intervalKind: mapIntervalKind(blockDTO.interval.kind),
            text: blockDTO.notes,
            yardageOverride: nil,
            patterns: SetPatterns(
                pace: mapPattern(blockDTO.pattern),
                stroke: nil,
                focus: []
            )
        )
        
        return PracticeSet(
            id: UUID(),
            title: nil,
            repeatCount: 1,
            lines: [line]
        )
    }
    
    // MARK: - Stroke Mapping
    
    private static func mapStroke(_ strokeDTO: StrokeDTO?) -> StrokeType? {
        guard let strokeDTO = strokeDTO else { return nil }
        
        switch strokeDTO {
        case .free:
            return .freestyle
        case .back:
            return .backstroke
        case .breast:
            return .breaststroke
        case .fly:
            return .butterfly
        case .im:
            return .im
        case .choice:
            return .choice
        case .mixed:
            return .freestyle // Default to freestyle for mixed
        }
    }
    
    // MARK: - Mode Mapping
    
    private static func mapMode(_ modeDTO: ModeDTO?) -> StrokeType? {
        guard let modeDTO = modeDTO else { return nil }
        
        switch modeDTO {
        case .swim:
            return .swim
        case .kick:
            return .kick
        case .pull:
            return .pull
        case .drill:
            return .drill
        case .scull:
            return .scull
        case .technique:
            return .technique
        }
    }
    
    // MARK: - Interval Mapping
    
    private static func mapIntervalKind(_ kindDTO: IntervalKindDTO) -> IntervalKind {
        switch kindDTO {
        case .sendoff:
            return .sendoff
        case .rest:
            return .rest
        case .none:
            return .none
        }
    }
    
    private static func mapIntervalType(_ kindDTO: IntervalKindDTO) -> IntervalType {
        switch kindDTO {
        case .sendoff:
            return .interval
        case .rest:
            return .rest
        case .none:
            return .interval // Default
        }
    }
    
    // MARK: - Pattern Mapping
    
    private static func mapPattern(_ patternDTO: PatternDTO?) -> PacePattern? {
        guard let patternDTO = patternDTO else { return nil }
        
        // Map common pattern types
        switch patternDTO.type.lowercased() {
        case "evenpace", "even":
            return .evenPace
        case "descend", "desc":
            return .descend
        case "build":
            return .build
        case "easy":
            return .easy
        case "cruise", "aerobic":
            return .cruise
        case "moderate", "strong":
            return .moderate
        case "fast":
            return .fast
        case "sprint":
            return .sprint
        case "threshold":
            return .threshold
        case "racepace", "race":
            return .racePace
        default:
            // For "other" or unrecognized, try to infer from raw
            if let raw = patternDTO.raw?.lowercased() {
                if raw.contains("easy") { return .easy }
                if raw.contains("aerobic") || raw.contains("cruise") { return .cruise }
                if raw.contains("threshold") { return .threshold }
                if raw.contains("sprint") { return .sprint }
                if raw.contains("fast") { return .fast }
            }
            return nil
        }
    }
}
