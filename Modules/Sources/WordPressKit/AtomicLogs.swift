import Foundation

public final class AtomicErrorLogEntry: Decodable {
    public let message: String?
    public let severity: String?
    public let kind: String?
    public let name: String?
    public let file: String?
    public let line: Int?
    public let timestamp: Date?

    @frozen public enum Severity: String {
        case user = "User"
        case warning = "Warning"
        case deprecated = "Deprecated"
        case fatalError = "Fatal error"
    }
}

public final class AtomicErrorLogsResponse: Decodable {
    public let totalResults: Int
    public let logs: [AtomicErrorLogEntry]
    public let scrollId: String?
}

public class AtomicWebServerLogEntry: Decodable {
    public let bodyBytesSent: Int?
    /// The possible values are `"true"` or `"false"`.
    public let cached: String?
    public let date: Date?
    public let httpHost: String?
    public let httpReferer: String?
    public let httpUserAgent: String?
    public let requestTime: Double?
    public let requestType: String?
    public let requestUrl: String?
    public let scheme: String?
    public let status: Int?
    public let timestamp: Int?
    public let type: String?
}

public final class AtomicWebServerLogsResponse: Decodable {
    public let totalResults: Int
    public let logs: [AtomicWebServerLogEntry]
    public let scrollId: String?
}
