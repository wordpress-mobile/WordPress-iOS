import UniformTypeIdentifiers
import WordPressData

// MARK: - Support for Files-based functionality

extension Blog {
    /// In conjunction with `allowedFileExtensions`, reports the
    /// [Uniform Type Identifiers](https://developer.apple.com/library/content/documentation/FileManagement/Conceptual/understanding_utis/understand_utis_intro/understand_utis_intro.html#//apple_ref/doc/uid/TP40001319-CH201-SW1)
    /// supported by this particular `Blog` instance. Supported files differ between
    /// [Wordpress.org](https://codex.wordpress.org/Uploading_Files)
    /// and [Wordpress.com](https://en.support.wordpress.com/accepted-filetypes/).
    ///
    /// This computed property is intended for use with `UIDocumentPickerController`.
    ///
    /// - returns: The collection of UTIs supported by this blog instance.
    ///
    var allowedTypeIdentifiers: [String] {
        let typeIdentifiers = allowedFileTypes.compactMap {
            UTType(filenameExtension: $0)?.identifier
        }

        // Fall back to broad types when the blog has no known allowed file types,
        // or none of the file extensions resolve to a known UTType. An empty list
        // would cause the document picker to grey out all files.
        return typeIdentifiers.isEmpty ? [UTType.content.identifier, UTType.zip.identifier] : typeIdentifiers
    }
}
