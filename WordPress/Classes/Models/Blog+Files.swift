import MobileCoreServices
import UniformTypeIdentifiers

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
        guard let allowedFileExtensions = allowedFileTypes as? Set<String> else {
            /**
                NB: For self-hosted plans, this collection has been observed to be empty. In that
                case, we fall back to base [System-Declared Uniform Type Identifiers](https://developer.apple.com/library/content/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html).
             */
            return [UTType.content.identifier, UTType.zip.identifier]
        }

        var typeIdentifiers = [String]()
        for pathExtension in allowedFileExtensions {
            let uti = UTType(filenameExtension: pathExtension)?.identifier

            if let validUTI = uti {
                typeIdentifiers.append(validUTI)
            }
        }

        return typeIdentifiers
    }
}
