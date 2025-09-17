import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

public enum LanguageModelHelper {
    public static var isSupported: Bool {
        guard #available(iOS 26, *) else { return false }
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

    public static func makeGenerateExcerptPrompt(
        content: String,
        length: GeneratedContentLength,
        style: GenerationStyle
    ) -> String {
        """
        Task: Create exactly 3 excerpts for a blog post.

        CRITICAL CONSTRAINTS:
        • Each excerpt MUST be \(length.promptModifier) (\(length.wordRange) words)
        • Style: \(style.promptDescription)

        EXCERPT REQUIREMENTS:
        * Follow the best practices for post excerpts esteblished in the WordPress ecosystem
        • First sentence: Strong hook that creates curiosity
        • Include the post's main value proposition
        • Use active voice (avoid "is", "are", "was", "were" when possible)
        • End with implicit promise of more information
        • Do not use ellipsis (...) at the end

        VARIATION GUIDELINES:
        Excerpt 1: Open with a question that addresses reader's problem
        Excerpt 2: Start with a bold statement or surprising fact
        Excerpt 3: Lead with the primary benefit or outcome

        SOURCE CONTENT:
        \(content)
        """
    }
}

public enum GenerationStyle: String, CaseIterable, RawRepresentable {
    case engaging
    case conversational
    case witty
    case formal
    case professional

    public var displayName: String {
        switch self {
        case .engaging:
            NSLocalizedString("generation.style.engaging", value: "Engaging", comment: "AI generation style")
        case .conversational:
            NSLocalizedString("generation.style.conversational", value: "Conversational", comment: "AI generation style")
        case .witty:
            NSLocalizedString("generation.style.witty", value: "Witty", comment: "AI generation style")
        case .formal:
            NSLocalizedString("generation.style.formal", value: "Formal", comment: "AI generation style")
        case .professional:
            NSLocalizedString("generation.style.professional", value: "Professional", comment: "AI generation style")
        }
    }

    public var promptDescription: String {
        switch self {
        case .engaging: "engaging and compelling tone"
        case .witty: "witty, creative, entertaining"
        case .conversational: "friendly and conversational tone"
        case .formal: "formal and academic tone"
        case .professional: "professional and polished tone"
        }
    }
}

public enum GeneratedContentLength: Int, CaseIterable, RawRepresentable {
    case short
    case medium
    case long

    public var displayName: String {
        switch self {
        case .short:
            NSLocalizedString("generation.length.short", value: "Short", comment: "Generated content length (needs to be short)")
        case .medium:
            NSLocalizedString("generation.length.medium", value: "Medium", comment: "Generated content length (needs to be short)")
        case .long:
            NSLocalizedString("generation.length.long", value: "Long", comment: "Generated content length (needs to be short)")
        }
    }

    public var trackingName: String {
        switch self {
        case .short: "short"
        case .medium: "medium"
        case .long: "long"
        }
    }

    public var promptModifier: String {
        switch self {
        case .short: "short"
        case .medium: "medium"
        case .long: "long"
        }
    }

    public var wordRange: String {
        switch self {
        case .short: "30-60"
        case .medium: "60-90"
        case .long: "120-150"
        }
    }
}
