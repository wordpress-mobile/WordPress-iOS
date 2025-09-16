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
        Generate three distinct excerpt options for the following post. Each excerpt should capture the essence of the content while being engaging enough to encourage readers to click through and read the full post.

        **Parameters:**
        - Excerpt Length: around \(length.promptModifier) (important!!!)
        - Writing Style: \(style.promptDescription)

        **Requirements for each excerpt:**

        1. Stay within the target word count
        2. Hook the reader within the first sentence
        3. Maintain the specified writing style throughout
        4. Include the most compelling point or benefit from the post
        5. Use active voice predominantly
        6. Follow other best practices for post excerpts established within the WordPress community

        **Generate three variations that differ in:**

        - Opening approach (question vs. statement vs. statistic/fact)
        - Emotional appeal (logical vs. emotional vs. aspirational)
        - Information density (high detail vs. broad strokes vs. balanced)

        **Post Content:**
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

    public var promptModifier: String {
        switch self {
        case .short: "50 words"
        case .medium: "100 words"
        case .long: "150 words"
        }
    }
}
