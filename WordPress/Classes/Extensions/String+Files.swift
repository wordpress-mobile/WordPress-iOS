import MobileCoreServices

// MARK: - Support for Files-based functionality

extension String {
    /// Returns the UTI for a given file extension
    ///
    /// - Parameter fileExtension: the path extension to characterize
    /// - Returns: the corresponding UTI (if it exists); `nil` otherwise
    static func typeIdentifier(for fileExtension: String) -> String? {
        return UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension,
            fileExtension as CFString,
            nil)?.takeUnretainedValue() as String?
    }

    /// Lightweight swift version of wordpress formatting.php sanitize_file_name function
    ///
    /// - Returns: sanitized filename to match api
    func sanitizeFileName() -> String {
        var fileName = folding(options: .diacriticInsensitive, locale: .current)

        let specialChars: Set<Character> = ["?", "[", "]", "/", "\\", "=", "<", ">", ":", ";", ",", "'", "\"", "&", "$", "#", "*", "(", ")", "|", "~", "`", "!", "{", "}", "%", "+", "’", "«", "»", "”", "“"]
        fileName.removeAll(where: { specialChars.contains($0) })

        return fileName
    }

}
