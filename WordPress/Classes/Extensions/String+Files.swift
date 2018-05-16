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
}
