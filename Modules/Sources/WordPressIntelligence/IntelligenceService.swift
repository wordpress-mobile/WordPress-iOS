import Foundation
import FoundationModels
import NaturalLanguage

public enum IntelligenceService {
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

    /// Extracts relevant text from post content, removing HTML and limiting size.
    public static func extractRelevantText(from post: String, ratio: CGFloat = 0.6) -> String {
        let extract = try? ContentExtractor.extractRelevantText(from: post)
        let postSizeLimit = Double(IntelligenceService.contextSizeLimit) * ratio
        return String((extract ?? post).prefix(Int(postSizeLimit)))
    }

    /// - note: As documented in https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models?changes=_10_5#Use-Instructions-to-set-the-locale-and-language
    static func makeLocaleInstructions(for locale: Locale = Locale.current) -> String {
        if Locale.Language(identifier: "en_US").isEquivalent(to: locale.language) {
            return "" // Skip the locale phrase for U.S. English.
        }
        return "The person's locale is \(locale.identifier)."
    }

    /// Detects the dominant language of the given text.
    ///
    /// - Parameter text: The text to analyze
    /// - Returns: The detected language code (e.g., "en", "es", "fr", "ja"), or nil if detection fails
    public static func detectLanguage(from text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let languageCode = recognizer.dominantLanguage else {
            return nil
        }

        return languageCode.rawValue
    }
}
