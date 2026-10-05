import Foundation

/// A request the app made, as the request log records it.
///
/// The log holds one of these per line, as JSON, in the order the requests were made. A test reads
/// it to check what the app sent, such as its analytics events, and not only what it showed.
public struct RecordedRequest: Codable, Equatable, Sendable {
    public let method: String
    public let url: URL

    /// The request's body, when it has one and it's text.
    public let body: String?

    /// The status of the response the request was answered with.
    public let status: Int

    /// The mapping file that answered the request, relative to the `mappings` directory, or `nil`
    /// when no mapping matched.
    public let fixture: String?
}
