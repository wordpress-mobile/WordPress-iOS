import Foundation

// Helper function that returns a localized string for Tests (which shouldn't be extracted by genstrings)
func i18n(_ content: String) -> String {
    return Bundle.main.localizedString(forKey: content, value: nil, table: nil)
}
