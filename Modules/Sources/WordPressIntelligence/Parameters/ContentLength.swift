import Foundation
import WordPressShared

/// Target length for generated text.
///
/// Ranges are calibrated for English and account for cross-language variance.
/// Sentences are the primary indicator; word counts accommodate language differences.
///
/// - **Short**: 1-2 sentences (15-35 words) - Social media, search snippets
/// - **Medium**: 2-4 sentences (30-90 words) - RSS feeds, blog listings
/// - **Long**: 5-7 sentences (90-130 words) - Detailed previews, newsletters
///
/// Word ranges are intentionally wide (2-2.3x) to handle differences in language
/// structure (German compounds, Romance wordiness, CJK tokenization).
public enum ContentLength: Int, CaseIterable, Sendable {
    case short
    case medium
    case long

    public var displayName: String {
        switch self {
        case .short:
            AppLocalizedString("generation.length.short", value: "Short", comment: "Generated content length (needs to be short)")
        case .medium:
            AppLocalizedString("generation.length.medium", value: "Medium", comment: "Generated content length (needs to be short)")
        case .long:
            AppLocalizedString("generation.length.long", value: "Long", comment: "Generated content length (needs to be short)")
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
        "\(sentenceRange.lowerBound)-\(sentenceRange.upperBound) sentences (\(wordRange.lowerBound)-\(wordRange.upperBound) words)"
    }

    public var sentenceRange: ClosedRange<Int> {
        switch self {
        case .short: 1...2
        case .medium: 2...4
        case .long: 5...7
        }
    }

    public var wordRange: ClosedRange<Int> {
        switch self {
        case .short: 15...35
        case .medium: 40...80
        case .long: 90...130
        }
    }
}
