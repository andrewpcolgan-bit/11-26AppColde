import Foundation

enum AppConfig {
    static var githubAPIKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "GITHUB_API_KEY") as? String
    }

    static var backendAnalyzeURL: URL? {
        if let urlString = Bundle.main.object(forInfoDictionaryKey: "BACKEND_ANALYZE_URL") as? String {
            return URL(string: urlString)
        }
        return nil
    }
}
