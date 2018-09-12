/// Encapsulates the content of the message to be presented in the "New" Card
struct NewsItem {
    let title: String
    let content: String
    let extendedInfoURL: URL
    let version: Decimal
}

extension NewsItem {
    private struct FileKeys {
        static let title = "Title"
        static let content = "Content"
        static let URL = "URL"
        static let version = "version"
    }

    init?(fileContent: [String: String]) {
        guard let title = fileContent[FileKeys.title],
            let content = fileContent[FileKeys.content],
            let urlString = fileContent[FileKeys.URL],
            let url = URL(string: urlString),
            let versionString = fileContent[FileKeys.version],
            let version = Decimal(string: versionString) else {
                return nil
        }

        self.init(title: title, content: content, extendedInfoURL: url, version: version)
    }
}

extension NewsItem: CustomStringConvertible {
    var description: String {
        return "\(title): \(content)"
    }
}

extension NewsItem: CustomDebugStringConvertible {
    var debugDescription: String {
        return description
    }
}
