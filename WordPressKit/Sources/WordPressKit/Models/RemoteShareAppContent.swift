/// Defines the information structure used for recommending the app to others.
///
public struct RemoteShareAppContent: Codable {
    /// A text content to share.
    public let message: String

    /// A URL string that directs the recipient to a page describing steps to get the app.
    public let link: String

    /// Convenience method that returns `link` as URL.
    public func linkURL() -> URL? {
        URL(string: link)
    }
}
