import Foundation

enum PromptHelper {
    // As documented in https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models?changes=_10_5#Use-Instructions-to-set-the-locale-and-language
    static func makeLocaleInstructions(for locale: Locale = Locale.current) -> String {
        if Locale.Language(identifier: "en_US").isEquivalent(to: locale.language) {
            // Skip the locale phrase for U.S. English.
            return ""
        } else {
            // Specify the person's locale with the exact phrase format.
            return "The person's locale is \(locale.identifier)."
        }
    }
}
