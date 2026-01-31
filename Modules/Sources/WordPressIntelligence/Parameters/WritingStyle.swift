import Foundation
import WordPressShared

/// Writing style for generated text.
public enum WritingStyle: String, CaseIterable, Sendable {
    case engaging
    case conversational
    case witty
    case formal
    case professional

    public var displayName: String {
        switch self {
        case .engaging:
            AppLocalizedString("generation.style.engaging", value: "Engaging", comment: "AI generation style")
        case .conversational:
            AppLocalizedString("generation.style.conversational", value: "Conversational", comment: "AI generation style")
        case .witty:
            AppLocalizedString("generation.style.witty", value: "Witty", comment: "AI generation style")
        case .formal:
            AppLocalizedString("generation.style.formal", value: "Formal", comment: "AI generation style")
        case .professional:
            AppLocalizedString("generation.style.professional", value: "Professional", comment: "AI generation style")
        }
    }

    var promptModifier: String {
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
