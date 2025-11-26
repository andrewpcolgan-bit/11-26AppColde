import Foundation

// MARK: - Exact shape returned by your Vercel /api/analyze
// MARK: - New Stats & Insights
struct PracticeIntensitySummary: Codable {
    let easyYards: Int
    let aerobicYards: Int
    let thresholdYards: Int
    let raceYards: Int
    let sprintYards: Int
    let workYards: Int
    let recoveryYards: Int
    
    var totalClassifiedYards: Int {
        easyYards + aerobicYards + thresholdYards + raceYards + sprintYards
    }
    
    enum CodingKeys: String, CodingKey {
        case easyYards = "easy_yards"
        case aerobicYards = "aerobic_yards"
        case thresholdYards = "threshold_yards"
        case raceYards = "race_yards"
        case sprintYards = "sprint_yards"
        case workYards = "work_yards"
        case recoveryYards = "recovery_yards"
    }
}

struct PracticeInsights: Codable {
    let difficultyScore: Int?
    let strainCategory: String?
    let focusTags: [String]
    let highlightBullets: [String]
    
    enum CodingKeys: String, CodingKey {
        case difficultyScore = "difficulty_score"
        case strainCategory = "strain_category"
        case focusTags = "focus_tags"
        case highlightBullets = "highlight_bullets"
    }
}

// MARK: - Exact shape returned by your Vercel /api/analyze
struct BackendAnalysisResult: Codable {
    let totalYards: Int
    let sectionYards: [String: Int]
    let strokePercentages: [String: Double]

    // From backend /api/analyze.js
    let aiSummary: String?            // short overall summary
    let aiTip: String?                // generic tip
    let practiceTag: String?          // e.g. "sprint free", "aerobic IM"
    let recoverySuggestions: String?  // full text block of stretches/recovery
    
    // New fields (Optional for backward compatibility)
    let intensitySummary: PracticeIntensitySummary?
    let insights: PracticeInsights?
    let recoveryPlan: RecoveryPlan?
    
    // Map JSON keys if needed (camelCase usually matches automatically)
    enum CodingKeys: String, CodingKey {
        case totalYards, sectionYards, strokePercentages, aiSummary, aiTip, practiceTag, recoverySuggestions
        case intensitySummary = "intensity_summary"
        case insights
        case recoveryPlan = "recovery_plan"
    }
}

// MARK: - Your existing app model
struct SectionDetail: Codable, Identifiable {
    var id: String { title }
    let title: String
    let lines: [String]
    let totalYards: Int
}

struct AnalyzedPractice: Codable, Identifiable {
    let id: String
    let date: String
    let formattedText: String
    let aiSummary: String
    let distanceYards: Int
    let durationMinutes: Int
    let sectionYards: [String: Int]
    let strokePercentages: [String: Double]
    let aiTip: String?
    let timeOfDay: String?
    let practiceTag: String?
    let recoverySuggestions: String?
    var title: String?
    
    // New fields
    let intensitySummary: PracticeIntensitySummary?
    let insights: PracticeInsights?
    
    // Phase 2: Structured Recovery Plan
    var recoveryPlan: RecoveryPlan?
    
    // Backward compatibility: generate recovery plan from text if needed
    mutating func ensureRecoveryPlan() {
        // If we already have a structured plan, use it
        if let plan = recoveryPlan, !plan.tasks.isEmpty {
            return
        }
        
        // Fall back to generating from text suggestions
        guard let text = recoverySuggestions, !text.isEmpty else { return }
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { line -> String in
                var clean = line
                if clean.hasPrefix("•") { clean = String(clean.dropFirst()) }
                if clean.hasPrefix("-") { clean = String(clean.dropFirst()) }
                return clean.trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else { return }
        
        let count = lines.count
        let third = Int(ceil(Double(count) / 3.0))
        
        var tasks: [RecoveryTask] = []
        
        for (index, line) in lines.enumerated() {
            let bucket: RecoveryBucket
            if index < third {
                bucket = .immediate
            } else if index < third * 2 {
                bucket = .today
            } else {
                bucket = .tomorrow
            }
            
            tasks.append(RecoveryTask(text: line, bucket: bucket))
        }
        
        self.recoveryPlan = RecoveryPlan(tasks: tasks)
    }
}

// MARK: - Error
enum AnalyzeError: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let s): return s
        }
    }
}

// MARK: - Service
final class AnalyzeService {

    func analyze(text: String, completion: @escaping (Result<AnalyzedPractice, AnalyzeError>) -> Void) {
        guard let url = AppConfig.backendAnalyzeURL else {
            completion(.failure(.message("Missing BACKEND_ANALYZE_URL in Info.plist")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["text": text]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.message("Network error: \(error.localizedDescription)")))
                return
            }

            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard (200...299).contains(status) else {
                let msg = String(data: data ?? Data(), encoding: .utf8) ?? "No body"
                completion(.failure(.message("Server error \(status): \(msg)")))
                return
            }

            guard let data = data else {
                completion(.failure(.message("Empty response")))
                return
            }

            do {
                // Debug: Print raw JSON to see what we got
                if let raw = String(data: data, encoding: .utf8) {
                    print("🔍 BACKEND RESPONSE:\n\(raw)")
                }
                
                // Case 1: Backend already sent clean JSON in BackendAnalysisResult shape
                if let backend = try? JSONDecoder().decode(BackendAnalysisResult.self, from: data) {
                    print("✅ Decoded BackendAnalysisResult directly. Intensity: \(backend.intensitySummary != nil)")
                    let analyzed = self.makeAnalyzedPractice(from: backend, text: text)
                    completion(.success(analyzed))
                    return
                }

                // Case 2: Wrapped as {"rawOutput": "json\n{...}"}
                struct Wrapper: Codable { let rawOutput: String }

                if let wrapped = try? JSONDecoder().decode(Wrapper.self, from: data) {
                    var cleaned = wrapped.rawOutput
                        .replacingOccurrences(of: "```json", with: "")
                        .replacingOccurrences(of: "```", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    // Strip leading "json" label that Gemini likes to add
                    if cleaned.lowercased().hasPrefix("json") {
                        cleaned = String(cleaned.dropFirst(4))
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    print("🔍 CLEANED JSON:\n\(cleaned)")

                    if let innerData = cleaned.data(using: .utf8) {
                        do {
                            let backend = try JSONDecoder().decode(BackendAnalysisResult.self, from: innerData)
                            print("✅ Decoded Wrapped BackendAnalysisResult. Intensity: \(backend.intensitySummary != nil)")
                            let analyzed = self.makeAnalyzedPractice(from: backend, text: text)
                            completion(.success(analyzed))
                            return
                        } catch {
                            print("⚠️ Failed to decode wrapped JSON: \(error)")
                        }
                    }
                }

                // Case 3: Raw string (non-wrapped)
                if var string = String(data: data, encoding: .utf8) {
                    string = string.trimmingCharacters(in: .whitespacesAndNewlines)

                    if string.lowercased().hasPrefix("json") {
                        string = String(string.dropFirst(4))
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }

                    if let innerData = string.data(using: .utf8) {
                        do {
                            let backend = try JSONDecoder().decode(BackendAnalysisResult.self, from: innerData)
                            print("✅ Decoded Raw String BackendAnalysisResult. Intensity: \(backend.intensitySummary != nil)")
                            let analyzed = self.makeAnalyzedPractice(from: backend, text: text)
                            completion(.success(analyzed))
                            return
                        } catch {
                            print("⚠️ Failed to decode raw string JSON: \(error)")
                        }
                    }
                }

                throw AnalyzeError.message("Unexpected data format")

            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "?"
                print("🔍 RAW RESPONSE:\n\(raw)")
                completion(.failure(.message("Decode error: \(error.localizedDescription)\nRaw: \(raw)")))
            }
        }.resume()
    }

    // MARK: - Helper
    private func makeAnalyzedPractice(from backend: BackendAnalysisResult, text: String) -> AnalyzedPractice {
        AnalyzedPractice(
            id: UUID().uuidString,
            date: ISO8601DateFormatter().string(from: Date()),
            formattedText: text,
            aiSummary: backend.aiSummary ?? "No summary",
            distanceYards: backend.totalYards,
            durationMinutes: 0,
            sectionYards: backend.sectionYards,
            strokePercentages: backend.strokePercentages,
            aiTip: backend.aiTip,
            timeOfDay: "", // safe default since backend doesn't provide it
            practiceTag: backend.practiceTag,
            recoverySuggestions: backend.recoverySuggestions,
            title: nil,
            intensitySummary: backend.intensitySummary,
            insights: backend.insights,
            recoveryPlan: backend.recoveryPlan
        )
    }
}
