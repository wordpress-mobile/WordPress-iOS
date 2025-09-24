import Foundation
import FoundationModels

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

    public static var generateExcerptInstructions: String {
        """
        Generate exactly 3 excerpts for the blog post and follow the instructions from the prompt regarding the length and the style.

        CRITICAL CONSTRAINTS:
        • Each excerpt MUST follow the style and the length requirements

        EXCERPT BEST PRACTICES:
        * Follow the best practices for post excerpts esteblished in the WordPress ecosystem
        • Include the post's main value proposition
        • Use active voice (avoid "is", "are", "was", "were" when possible)
        • End with implicit promise of more information
        • Do not use ellipsis (...) at the end
        * Focus on value, not summary
        * Include strategic keywords naturall
        * Write independently from the introduction – excerpt shouldn't just duplicate your opening paragraph. While your introduction eases readers into the topic, your excerpt needs to work as standalone copy that makes sense out of context—whether it appears in search results, social media cards, or email newsletters.

        VARIATION GUIDELINES:
        Excerpt 1: Open with a question that addresses reader's problem
        Excerpt 2: Start with a bold statement or surprising fact
        Excerpt 3: Lead with the primary benefit or outcome
        """
    }

    public static func makeGenerateExcerptPrompt(
        content: String,
        length: GeneratedContentLength,
        style: GenerationStyle
    ) -> String {
        """
        Generate excerpts with the following constraints (MUST FOLLOW):

        • Length: \(length.promptModifier)
        • Style: \(style.promptModifier)

        SOURCE POST CONTENT:
        \(content)
        """
    }

    public static var generateMoreOptionsPrompt: String {
        "Generate additional three options"
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

    public var promptModifier: String {
        "\(rawValue) (\(promptModifierDetails))"
    }

    var promptModifierDetails: String {
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

    public var trackingName: String { name }

    public var promptModifier: String {
        "\(wordRange) words"
    }

    private var name: String {
        switch self {
        case .short: "short"
        case .medium: "medium"
        case .long: "long"
        }
    }

    private var wordRange: String {
        switch self {
        case .short: "20-40"
        case .medium: "50-70"
        case .long: "120-180"
        }
    }
}
