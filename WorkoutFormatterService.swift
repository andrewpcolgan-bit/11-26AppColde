import Foundation

enum WorkoutFormatterError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL configuration"
        case .invalidResponse:
            return "Received invalid response from server"
        case .serverError(let statusCode, let message):
            if let message = message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server error (\(statusCode))"
        case .decodingError:
            return "Failed to parse server response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

final class WorkoutFormatterService {
    
    /// Format workout text using AI backend
    /// - Parameters:
    ///   - text: Raw workout text to format
    ///   - poolType: Pool type (SCY, SCM, LCM), defaults to SCY
    ///   - defaultSection: Default section if no headers found, defaults to "main"
    /// - Returns: Formatted workout response
    static func formatWorkoutText(
        text: String,
        poolType: String = "SCY",
        defaultSection: String = "main"
    ) async throws -> FormatWorkoutResponseDTO {
        
        // Get base URL from config (reuse BACKEND_ANALYZE_URL)
        guard let baseURL = AppConfig.backendAnalyzeURL else {
            throw WorkoutFormatterError.invalidURL
        }
        
        // Build URL for formatter endpoint
        let urlString = baseURL.absoluteString.replacingOccurrences(of: "/api/analyze", with: "/api/formatWorkoutText")
        
        guard let url = URL(string: urlString) else {
            throw WorkoutFormatterError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90 // 90 second timeout for AI processing
        
        // Build request body
        let body: [String: Any] = [
            "text": text,
            "poolType": poolType,
            "defaultSection": defaultSection
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            throw WorkoutFormatterError.networkError(error)
        }
        
        // Make network request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw WorkoutFormatterError.networkError(error)
        }
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WorkoutFormatterError.invalidResponse
        }
        
        // Handle error status codes
        guard (200..<300).contains(httpResponse.statusCode) else {
            // Try to decode error message from response
            var errorMessage: String?
            if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorJSON["error"] as? String {
                errorMessage = message
            }
            throw WorkoutFormatterError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Decode response
        let decoder = JSONDecoder()
        do {
            let formattedResponse = try decoder.decode(FormatWorkoutResponseDTO.self, from: data)
            return formattedResponse
        } catch {
            print("❌ Decoding error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw response: \(jsonString)")
            }
            throw WorkoutFormatterError.decodingError(error)
        }
    }
}
