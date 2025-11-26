import Foundation

/// Parses free-text workout descriptions into structured PracticeSection and PracticeSet models
class WorkoutParser {
    
    struct ParseResult {
        var sections: [PracticeSection]
        var totalYards: Int
        var title: String?
        var unparsedLines: [String]
        var warnings: [String]
        
        init(sections: [PracticeSection] = [], title: String? = nil, unparsedLines: [String] = [], warnings: [String] = []) {
            self.sections = sections
            self.title = title
            self.unparsedLines = unparsedLines
            self.warnings = warnings
            self.totalYards = sections.reduce(0) { $0 + $1.totalYards }
        }
    }
    
    private let sectionKeywords: [String: String] = [
        // Warmup variations
        "warmup": "Warmup",
        "warm-up": "Warmup",
        "warm up": "Warmup",
        "wu": "Warmup",
        
        // Pre-Set variations
        "pre-set": "Pre-Set",
        "preset": "Pre-Set",
        "pre set": "Pre-Set",
        "ps": "Pre-Set",
        
        // Main Set variations
        "main": "Main Set",
        "main set": "Main Set",
        "ms": "Main Set",
        
        // Post-Set variations
        "post-set": "Post-Set / Technique",
        "post set": "Post-Set / Technique",
        "post": "Post-Set / Technique",
        "reset": "Post-Set / Technique",
        "recovery": "Post-Set / Technique",
        "technique": "Post-Set / Technique",
        "drills": "Post-Set / Technique",
        
        // Cooldown variations
        "cooldown": "Cooldown",
        "cool-down": "Cooldown",
        "cool down": "Cooldown",
        "warmdown": "Cooldown",
        "warm-down": "Cooldown",
        "warm down": "Cooldown",
        "cd": "Cooldown"
    ]
    
    func parse(_ text: String) -> ParseResult {
        var sections: [PracticeSection] = []
        var currentSection: PracticeSection?
        var warnings: [String] = []
        var title: String?
        
        // State for repeated groups
        var pendingRepeatCount: Int = 1
        var groupedLines: [PracticeLine] = []
        
        let lines = text.components(separatedBy: .newlines)
        var hasFoundFirstSection = false
        
        // Helper to flush any pending group to the current section
        func flushGroup() {
            guard !groupedLines.isEmpty else {
                pendingRepeatCount = 1
                return
            }
            
            if currentSection == nil {
                currentSection = PracticeSection(id: UUID(), label: "Main Set", sets: [])
            }
            
            let set = PracticeSet(
                id: UUID(),
                title: nil,
                repeatCount: pendingRepeatCount,
                lines: groupedLines
            )
            currentSection?.sets.append(set)
            
            // Reset state
            pendingRepeatCount = 1
            groupedLines = []
        }
        
        for (index, rawLine) in lines.enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            
            guard !line.isEmpty else {
                // Empty line can signal end of a group
                flushGroup()
                continue
            }
            if line.hasPrefix("//") || line.hasPrefix("#") { continue }
            
            // Check for section header
            if let sectionName = detectSection(line) {
                flushGroup() // Ensure any previous group is finished
                
                hasFoundFirstSection = true
                if let section = currentSection, !section.sets.isEmpty {
                    sections.append(section)
                }
                currentSection = PracticeSection(id: UUID(), label: sectionName, sets: [])
                continue
            }
            
            // Handle Metadata (Title/Notes) BEFORE the first section
            if !hasFoundFirstSection {
                if title == nil {
                    title = line
                    continue
                }
                continue
            }
            
            // Check for "Rounds" / "Through" line (e.g. "2x through:", "3 rounds")
            if let rounds = extractRounds(from: line) {
                flushGroup() // Finish any previous group
                pendingRepeatCount = rounds
                continue
            }
            
            // Check indentation to determine if this line belongs to a group
            let isIndented = rawLine.first?.isWhitespace == true
            
            // IMPORTANT: Before treating a line as a descriptor, check if it's a valid set
            // Lines like "– 3x (4x25 @ :25)" should be parsed as sets, not descriptors
           // Strip leading dash/hyphen and try to parse
            var lineToTry = line
            let startsWithDash = (line.hasPrefix("-") || line.hasPrefix("–"))
            if startsWithDash {
                lineToTry = cleanDescriptor(line)
            }
            
            // Try to parse the line as a set/line
            if let set = parseSetLine(lineToTry) {
                // Successfully parsed - check if it actually has distance/reps or is just text
                let hasValidData = set.lines.first?.distance != nil || set.lines.first?.reps != nil
                
                // If it has valid data, treat as a set
                // If it's just text AND started with dash, treat as descriptor
                if !hasValidData && startsWithDash {
                    // This is a descriptor line (e.g., "– notes about previous set")
                    if pendingRepeatCount > 1 && !groupedLines.isEmpty {
                        var lastLine = groupedLines.removeLast()
                        lastLine.text += " " + lineToTry
                        groupedLines.append(lastLine)
                    } else if pendingRepeatCount == 1,
                              let section = currentSection,
                              !section.sets.isEmpty,
                              var lastSet = section.sets.last,
                              var lastLine = lastSet.lines.last {
                        lastLine.text += " " + lineToTry
                        lastSet.lines[lastSet.lines.count - 1] = lastLine
                        currentSection?.sets[section.sets.count - 1] = lastSet
                    }
                    continue
                }
                
                // This is a valid set
                // If we have a pending group > 1
                if pendingRepeatCount > 1 {
                    // If indented, add to group
                    if isIndented {
                        // Extract the single line from the parsed set
                        if let firstLine = set.lines.first {
                            groupedLines.append(firstLine)
                        }
                    } else {
                        // Not indented -> End of group
                        flushGroup()
                        
                        // Add this line as a normal set
                        if currentSection == nil {
                            currentSection = PracticeSection(id: UUID(), label: "Main Set", sets: [])
                        }
                        currentSection?.sets.append(set)
                    }
                } else {
                    // Normal parsing (no group)
                    if currentSection == nil {
                        currentSection = PracticeSection(id: UUID(), label: "Main Set", sets: [])
                    }
                    currentSection?.sets.append(set)
                }
            }
        }
        
        flushGroup() // Final flush
        
        if let section = currentSection, !section.sets.isEmpty {
            sections.append(section)
        }
        
        if sections.isEmpty && !text.isEmpty {
            warnings.append("No sections found. Try adding 'Main Set' or 'Warmup'.")
        }
        
        return ParseResult(sections: sections, title: title, unparsedLines: [], warnings: warnings)
    }
    
    private func cleanDescriptor(_ line: String) -> String {
        return line.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "^[–-]\\s*", with: "", options: .regularExpression)
    }
    
    private func extractRounds(from line: String) -> Int? {
        // Matches: "2x through", "3 rounds", "2 x through", "4x:", "2x thru"
        let pattern = #"^(\d+)\s*(?:x|×)?\s*(?:rounds?|through|thru|:)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        
        let nsString = line as NSString
        if let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsString.length)) {
            return Int(nsString.substring(with: match.range(at: 1)))
        }
        return nil
    }
    
    private func extractRepsAndDistance(from line: String) -> (Int, Int, String)? {
        // 0. Pre-process nested sets: "3x (4x25...)" -> "12x25..."
        // Regex to find "Ax (BxC" pattern
        let nestedPattern = #"^(\d+)\s*[x×]\s*\(?\s*(\d+)\s*[x×]\s*(\d+)"#
        if let nestedRegex = try? NSRegularExpression(pattern: nestedPattern, options: .caseInsensitive),
           let match = nestedRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
            
            let nsString = line as NSString
            let outerReps = Int(nsString.substring(with: match.range(at: 1))) ?? 1
            let innerReps = Int(nsString.substring(with: match.range(at: 2))) ?? 1
            let distance = Int(nsString.substring(with: match.range(at: 3))) ?? 0
            
            let totalReps = outerReps * innerReps
            
            // Construct new string starting with "12x25" and appending the rest of the line after the match
            // We need to be careful about where the match ended.
            // The match covers "3x (4x25". We need to skip the ")" if it exists?
            // Actually, simpler: Just return the values and the rest of the string after the distance.
            
            let matchEndIndex = match.range(at: 3).location + match.range(at: 3).length
            var remaining = nsString.substring(from: matchEndIndex)
            
            // If next char is ")", skip it
            if remaining.trimmingCharacters(in: .whitespaces).hasPrefix(")") {
                if let parenIndex = remaining.firstIndex(of: ")") {
                    remaining = String(remaining[remaining.index(after: parenIndex)...])
                }
            }
            
            return (totalReps, distance, remaining)
        }

        // 1. Try "4x100" or "4 x 100"
        let pattern = #"^(\d+)\s*[x×]\s*(\d+)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
            
            let nsString = line as NSString
            let reps = Int(nsString.substring(with: match.range(at: 1))) ?? 1
            let distance = Int(nsString.substring(with: match.range(at: 2))) ?? 0
            
            let matchEndIndex = match.range(at: 2).location + match.range(at: 2).length
            let remaining = nsString.substring(from: matchEndIndex)
            
            return (reps, distance, remaining)
        }
        
        // 2. Try just a distance: "100 ez" or "200 swim"
        let distanceOnlyPattern = #"^(\d+)(?:\s|$)"#
        if let distanceRegex = try? NSRegularExpression(pattern: distanceOnlyPattern, options: .caseInsensitive),
           let match = distanceRegex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
            
            let nsString = line as NSString
            let distance = Int(nsString.substring(with: match.range(at: 1))) ?? 0
            let remaining = nsString.substring(from: match.range.location + match.range.length)
            
            return (1, distance, remaining)
        }
        
        return nil
    }
    
    private func detectSection(_ line: String) -> String? {
        let normalized = line.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Exact match check
        if let sectionName = sectionKeywords[normalized] {
            return sectionName
        }
        
        // Prefix match check - relaxed to allow "Post Set - Pull"
        // BUT strict enough to avoid false positives
        for (keyword, sectionName) in sectionKeywords {
            if normalized.starts(with: keyword) {
                // Ensure it's a whole word match or followed by separator
                let remaining = normalized.dropFirst(keyword.count)
                
                // Must be followed by space, dash, colon, or be empty
                // Also check for "warm down" specifically if keyword is "warm"
                if remaining.isEmpty || 
                   remaining.first == " " || 
                   remaining.first == "-" || 
                   remaining.first == ":" || 
                   remaining.first == "–" {
                    return sectionName
                }
            }
        }
        
        return nil
    }
    
    private func parseSetLine(_ line: String) -> PracticeSet? {
        var remaining = line
        
        // Skip pure descriptive lines (goals, notes without numbers)
        // PERMISSIVE CHANGE: We now accept EVERYTHING.
        // If it has no numbers, it's just a note line.
        
        // Handle labeled sets like "A. Kick focus – 400" or "1–2: Fly"
        remaining = stripLabel(from: remaining)
        
        // Handle parenthetical notes like "(light pull)" - extract but keep
        let parentheticalNotes = extractParentheticalNotes(from: &remaining)
        
        // Try to extract reps and distance
        if let (reps, distance, afterDistance) = extractRepsAndDistance(from: remaining) {
            // SUCCESSFUL PARSE
            remaining = afterDistance
            
            let stroke = extractStroke(from: &remaining)
            let (intervalSeconds, intervalKind) = extractInterval(from: &remaining)
            let effort = extractEffort(from: &remaining)
            
            // 6. Clean up remaining text
            remaining = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Remove leading/trailing separators like "-", "–", ","
            let separatorPattern = #"^[–-]\s*|\s*[–-]$|^,\s*|\s*,$"#
            remaining = remaining.replacingOccurrences(of: separatorPattern, with: "", options: .regularExpression)
            
            // If remaining text is just "choice" or similar to what we already parsed, clear it
            if let s = stroke, remaining.lowercased() == s.rawValue.lowercased() {
                remaining = ""
            }
            
            // Add parenthetical notes back in if they exist
            if !parentheticalNotes.isEmpty {
                remaining = remaining.isEmpty ? parentheticalNotes : "\(remaining) \(parentheticalNotes)"
            }
            
            // Create line
            let practiceLine = PracticeLine(
                id: UUID(),
                reps: reps,
                distance: distance,
                stroke: stroke,
                interval: intervalSeconds.map { IntervalFormatter.format(seconds: $0) },
                intervalType: intervalKind == .rest ? .rest : .interval,
                intervalSeconds: intervalSeconds,
                intervalKind: intervalKind,
                text: remaining,
                yardageOverride: nil,
                patterns: SetPatterns(pace: effort, stroke: nil, focus: [])
            )
            
            return PracticeSet(id: UUID(), title: nil, repeatCount: 1, lines: [practiceLine])
            
        } else if let totalYards = extractTotal(from: remaining) {
            // TOTAL / PRESET LINE
            return createSimpleSet(yards: totalYards, notes: remaining)
            
        } else {
            // FALLBACK: TEXT-ONLY LINE (Permissive)
            // Create a line with 0 distance/reps, just text
            let line = PracticeLine(
                id: UUID(),
                reps: nil,
                distance: nil,
                stroke: nil,
                interval: nil,
                intervalType: .interval,
                intervalSeconds: nil,
                intervalKind: .none,
                text: line, // Use original full line
                yardageOverride: nil,
                patterns: SetPatterns()
            )
            return PracticeSet(id: UUID(), title: nil, repeatCount: 1, lines: [line])
        }
    }
    
    private func stripLabel(from line: String) -> String {
        // Remove labels like "A. ", "1–2: ", "B. ", etc.
        let pattern = #"^[A-Z]\.\s*|^\d+[–-]\d+:\s*"#
        return line.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
    
    private func extractParentheticalNotes(from line: inout String) -> String {
        let pattern = #"\(([^)]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return ""
        }
        
        var notes: [String] = []
        let nsString = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsString.length))
        
        for match in matches.reversed() {
            if match.range(at: 1).location != NSNotFound {
                let note = nsString.substring(with: match.range(at: 1))
                notes.insert(note, at: 0)
                line.removeSubrange(Range(match.range, in: line)!)
            }
        }
        
        return notes.joined(separator: ", ")
    }
    
    private func extractTotal(from line: String) -> Int? {
        // Match patterns like "Total: 600", "Preset: 1000", or just "600" if it's the only number
        let patterns = [
            #"(?:total|preset|warmup|cooldown):\s*(\d+)"#,
            #"^(\d{3,})\s*$"# // 3+ digits alone on line
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
                let nsString = line as NSString
                if let yards = Int(nsString.substring(with: match.range(at: 1))) {
                    return yards
                }
            }
        }
        
        return nil
    }
    
    private func createSimpleSet(yards: Int, notes: String) -> PracticeSet {
        let line = PracticeLine(
            id: UUID(),
            reps: 1,
            distance: yards,
            stroke: nil,
            interval: nil,
            intervalType: .interval,
            intervalSeconds: nil,
            intervalKind: .none,
            text: notes,
            yardageOverride: nil,
            patterns: SetPatterns()
        )
        
        return PracticeSet(id: UUID(), title: nil, repeatCount: 1, lines: [line])
    }
    
    
    private func extractStroke(from line: inout String) -> StrokeType? {
        let strokeKeywords: [(String, StrokeType)] = [
            ("free", .freestyle),
            ("freestyle", .freestyle),
            ("back", .backstroke),
            ("backstroke", .backstroke),
            ("breast", .breaststroke),
            ("breaststroke", .breaststroke),
            ("fly", .butterfly),
            ("butterfly", .butterfly),
            ("im", .im),
            ("kick", .kick),
            ("pull", .pull),
            ("drill", .drill),
            ("swim", .swim),
            ("choice", .choice)
        ]
        
        let normalized = line.lowercased()
        
        for (keyword, strokeType) in strokeKeywords {
            if let range = normalized.range(of: "\\b\(keyword)\\b", options: .regularExpression) {
                line.removeSubrange(range)
                return strokeType
            }
        }
        
        return nil
    }
    
    private func extractInterval(from line: inout String) -> (seconds: Int?, kind: IntervalKind) {
        // Handle ranges like @ :55-1:05 or @ :55–1:05 (hyphen or en-dash)
        // We take the first value as the base interval for calculation
        let sendoffPattern = #"@\s*(?:(\d+):)?(\d+)(?:\s*[–-]\s*(?:(\d+):)?(\d+))?"#
        
        if let regex = try? NSRegularExpression(pattern: sendoffPattern),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
            let nsString = line as NSString
            
            let minutes = match.range(at: 1).location != NSNotFound ? 
                Int(nsString.substring(with: match.range(at: 1))) ?? 0 : 0
            let seconds = Int(nsString.substring(with: match.range(at: 2))) ?? 0
            let totalSeconds = minutes * 60 + seconds
            
            line.removeSubrange(Range(match.range, in: line)!)
            return (totalSeconds, .sendoff)
        }
        
        let restPattern = #"(?:(\d+):)?(\d+)\s*rest"#
        if let regex = try? NSRegularExpression(pattern: restPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)) {
            let nsString = line as NSString
            
            let minutes = match.range(at: 1).location != NSNotFound ?
                Int(nsString.substring(with: match.range(at: 1))) ?? 0 : 0
            let seconds = Int(nsString.substring(with: match.range(at: 2))) ?? 0
            let totalSeconds = minutes * 60 + seconds
            
            line.removeSubrange(Range(match.range, in: line)!)
            return (totalSeconds, .rest)
        }
        
        return (nil, .none)
    }
    
    private func extractEffort(from line: inout String) -> PacePattern? {
        let effortKeywords: [(String, PacePattern)] = [
            ("easy", .easy),
            ("aerobic", .cruise),
            ("moderate", .moderate),
            ("strong", .moderate),
            ("threshold", .threshold),
            ("race", .racePace),
            ("sprint", .sprint),
            ("fast", .fast),
            ("descend", .descend),
            ("build", .build)
        ]
        
        let normalized = line.lowercased()
        
        for (keyword, pattern) in effortKeywords {
            if let range = normalized.range(of: "\\b\(keyword)\\b", options: .regularExpression) {
                line.removeSubrange(range)
                return pattern
            }
        }
        
        return nil
    }
}
