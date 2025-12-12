import Foundation
import FoundationModels

/// Service for AI-powered content generation and analysis features.
///
/// This service provides tag suggestions, post summaries, excerpt generation,
/// and other intelligence features using Foundation Models (iOS 26+).
public actor IntelligenceService {
    /// Maximum context size for language model sessions (in tokens).
    ///
    /// A single token corresponds to three or four characters in languages like
    /// English, Spanish, or German, and one token per character in languages like
    /// Japanese, Chinese, or Korean. In a single session, the sum of all tokens
    /// in the instructions, all prompts, and all outputs count toward the context window size.
    ///
    /// https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models#Consider-context-size-limits-per-session
    public static let contextSizeLimit = 4096

    /// Checks if intelligence features are supported on the current device.
    public nonisolated static var isSupported: Bool {
        guard #available(iOS 26, *) else {
            return false
        }
        switch SystemLanguageModel.default.availability {
        case .available:
            return true
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled, .modelNotReady:
                return true
            case .deviceNotEligible:
                return false
            @unknown default:
                return false
            }
        }
    }

    public init() {}

    // MARK: - Public API

    /// Suggests tags for a WordPress post.
    @available(iOS 26, *)
    public func suggestTags(post: String, siteTags: [String] = [], postTags: [String] = []) async throws -> [String] {
        try await TagSuggestion().generate(post: post, siteTags: siteTags, postTags: postTags)
    }

    /// Summarizes a support ticket to a short title.
    @available(iOS 26, *)
    public func summarizeSupportTicket(content: String) async throws -> String {
        try await SupportTicketSummary.execute(content: content)
    }

    /// Extracts relevant text from post content (removes HTML, limits size).
    public nonisolated func extractRelevantText(from post: String, ratio: CGFloat = 0.6) -> String {
        Self.extractRelevantText(from: post, ratio: ratio)
    }

    // MARK: - Shared Utilities

    /// Extracts relevant text from post content, removing HTML and limiting size.
    public nonisolated static func extractRelevantText(from post: String, ratio: CGFloat = 0.6) -> String {
        let extract = try? ContentExtractor.extractRelevantText(from: post)
        let postSizeLimit = Double(IntelligenceService.contextSizeLimit) * ratio
        return String((extract ?? post).prefix(Int(postSizeLimit)))
    }
}
