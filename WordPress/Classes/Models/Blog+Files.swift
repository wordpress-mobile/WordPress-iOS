import MobileCoreServices


extension Blog {
    var allowedTypeIdentifiers: [String] {
        guard let allowedFileExtensions = allowedFileTypes as? Set<String> else {
            return [String(kUTTypeContent), String(kUTTypeZipArchive)]
        }

        var typeIdentifiers = [String]()
        for pathExtension in allowedFileExtensions {
            let uti = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassFilenameExtension,
                pathExtension as CFString,
                nil)?.takeUnretainedValue() as String?

            if let validUTI = uti {
                typeIdentifiers.append(validUTI)
            }
        }

        return typeIdentifiers
    }
}
