import Foundation

/// Information the share path needs to authenticate, download, and name a
/// single item. The URL and MIME type drive the request and filename.
public struct DownloadableMediaItem: Sendable {
    public let sourceUrl: URL
    public let mimeType: String?
    public let suggestedFilename: String?

    public init(sourceUrl: URL, mimeType: String?, suggestedFilename: String?) {
        self.sourceUrl = sourceUrl
        self.mimeType = mimeType
        self.suggestedFilename = suggestedFilename
    }
}

/// App-injected authenticated downloader. Returns local file URLs suitable
/// for `UIActivityViewController` activity items. Throws on any download or
/// auth failure; the detail VM surfaces the error in `shareErrorMessage`.
@MainActor
public protocol MediaDetailShareService: AnyObject {
    func downloadForSharing(items: [DownloadableMediaItem]) async throws -> [URL]
}
