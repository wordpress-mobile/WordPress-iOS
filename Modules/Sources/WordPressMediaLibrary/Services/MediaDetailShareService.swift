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

/// Output of a successful `downloadForSharing(items:)`. `urls` are the local
/// file URLs to hand to `UIActivityViewController`. `cleanup`, when non-nil,
/// removes the service-owned temp scope (typically the per-batch directory
/// under `temporaryDirectory`); `MediaDetailViewModel.SharePayload` invokes
/// it on activity-sheet dismissal or selection-mode exit. The closure is the
/// only ownership signal — callers do not infer ownership from URL paths.
public struct BulkShareDownloadResult: Sendable {
    public let urls: [URL]
    public let cleanup: (@Sendable () -> Void)?

    public init(urls: [URL], cleanup: (@Sendable () -> Void)? = nil) {
        self.urls = urls
        self.cleanup = cleanup
    }
}

/// App-injected authenticated downloader. Returns local file URLs suitable
/// for `UIActivityViewController` activity items plus an optional cleanup
/// closure for the service-owned temp scope. Throws on any download or
/// auth failure; the detail VM surfaces the error in `shareErrorMessage`.
@MainActor
public protocol MediaDetailShareService: AnyObject {
    func downloadForSharing(items: [DownloadableMediaItem]) async throws -> BulkShareDownloadResult
}
