private struct RemoteEditorSettings: Codable {
    let editorMobile: String
    let editorWeb: String
}

public struct EditorSettings {
    public enum Error: Swift.Error {
        case decodingFailed
        case unknownEditor(String)
        case badRequest
        case badResponse
    }

    /// Editor choosen by the user to be used on Mobile
    ///
    /// - gutenberg: The block editor
    /// - aztec: The mobile "classic" editor
    /// - notSet: The user has never saved they preference on remote
    public enum Mobile: String {
        case gutenberg
        case aztec
        case notSet = ""
    }

    /// Editor choosen by the user to be used on Web
    ///
    /// - classic: The classic editor
    /// - gutenberg: The block editor
    public enum Web: String {
        case classic
        case gutenberg
    }

    public let mobile: Mobile
    public let web: Web
}

extension EditorSettings {
    init(with response: Any) throws {
        guard let response = response as? [String: AnyObject] else {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: nil)
        }

        let data = try JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
        let editorPreferenesRemote = try JSONDecoder.apiDecoder.decode(RemoteEditorSettings.self, from: data)
        try self.init(with: editorPreferenesRemote)
    }

    private init(with remote: RemoteEditorSettings) throws {
        guard
            let mobile = Mobile(rawValue: remote.editorMobile),
            let web = Web(rawValue: remote.editorWeb)
        else {
            throw Error.decodingFailed
        }
        self = EditorSettings(mobile: mobile, web: web)
    }
}
