import SwiftUI

/// Resolves the featured image of the posts and pages whose rows are on screen.
///
/// The featured image isn't part of any stats response, so it has to be read from the
/// site's posts endpoint. The Posts & Pages list is a poor fit for resolving them all up
/// front: the stats API bounds each day's results rather than the summary, so a busy
/// site's detail screen routinely carries several hundred rows. The rows therefore ask for
/// their own thumbnail as they appear, and the store gathers those asks into one request
/// per batch, dropping IDs it has already asked about.
@MainActor
final class PostThumbnailStore: ObservableObject {
    /// The featured image of every post resolved so far. A post the site reports no
    /// featured image for is absent, which leaves its row on the type glyph.
    @Published private(set) var thumbnails: [Int: URL] = [:]

    private let service: any PostThumbnailService
    private let batchSize: Int
    private let batchDelay: Duration

    /// Every ID asked about, so the same post is never looked up twice.
    private var requestedIDs: Set<Int> = []
    /// IDs waiting for the next request to go out.
    private var pendingIDs: [Int] = []
    private var batchTask: Task<Void, Never>?

    init(
        service: any PostThumbnailService,
        batchSize: Int = 25,
        batchDelay: Duration = .milliseconds(100)
    ) {
        self.service = service
        self.batchSize = batchSize
        self.batchDelay = batchDelay
    }

    /// Asks for the featured image of a post whose row has come on screen.
    ///
    /// Safe to call repeatedly: an ID already looked up, or already waiting to be, is
    /// ignored.
    func requestThumbnail(forPostID postID: Int) {
        guard !requestedIDs.contains(postID) else { return }
        requestedIDs.insert(postID)
        pendingIDs.append(postID)

        if pendingIDs.count >= batchSize {
            sendPendingRequest()
        } else if batchTask == nil {
            // Scrolling realizes rows a few at a time, so wait briefly for the rest of
            // the screenful rather than spending a request on the first row of it.
            let batchDelay = self.batchDelay
            batchTask = Task { [weak self] in
                try? await Task.sleep(for: batchDelay)
                guard !Task.isCancelled else { return }
                self?.sendPendingRequest()
            }
        }
    }

    private func sendPendingRequest() {
        batchTask?.cancel()
        batchTask = nil

        let batch = pendingIDs
        pendingIDs = []
        guard !batch.isEmpty else { return }

        Task { [weak self, service] in
            do {
                let urls = try await service.getFeaturedImageURLs(forPostIDs: batch)
                self?.thumbnails.merge(urls) { _, new in new }
            } catch {
                // The rows stay on their type glyph. Forget the batch so a row asks
                // again the next time it is realized. Nothing re-drives the request on
                // its own, so a list short enough to need no scrolling keeps its glyphs
                // until the screen is opened afresh.
                self?.requestedIDs.subtract(batch)
            }
        }
    }
}

// MARK: - Environment

private struct PostThumbnailStoreKey: EnvironmentKey {
    static let defaultValue: PostThumbnailStore? = nil
}

extension EnvironmentValues {
    /// Set only by the Posts & Pages detail screen, which is the one place a post row
    /// draws a thumbnail. Everywhere else – the Posts & Pages card, and the post lists on
    /// the author and UTM screens – it's nil and the row has no leading content.
    var postThumbnailStore: PostThumbnailStore? {
        get { self[PostThumbnailStoreKey.self] }
        set { self[PostThumbnailStoreKey.self] = newValue }
    }
}
