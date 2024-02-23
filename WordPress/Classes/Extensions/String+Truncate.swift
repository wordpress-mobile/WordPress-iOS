import Foundation

extension String {

    /// Trims the trailing characters from the string to ensure the resulting string doesn't exceed the provided limit.
    /// If the string is equal to or shorter than the limit, the string is returned without modifications
    /// If the string is longer, the trailing characters are trimmed and replaced with an ellipsis character,
    /// ensuring the length is equal to the limit
    func truncate(with limit: Int) -> String {
        guard count > limit else {
            return self
        }
        let prefix = self.prefix(limit - 1)
        return "\(prefix)…"
    }
}
