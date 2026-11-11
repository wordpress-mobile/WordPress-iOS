import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressShared

/// Exports the saved Reader posts kept in the WordPress.com account as a JSON file, and saves the
/// posts in such a file to the account.
struct ReaderSavedPostsExporter {

    struct Envelope: Codable {
        var exportDate: String
        var postCount: Int
        var posts: [ExportedPost]
        var appVersion: String
    }

    struct ExportedPost: Codable {
        var title: String
        var url: String
        var author: String
        var siteName: String
        var siteURL: String
        var date: String?
        var summary: String
        var tags: [String]?
        var featuredImageURL: String?
        var siteID: UInt?
        var postID: UInt?
        var feedID: UInt?
        var feedItemID: UInt?
        var isFeed: Bool
    }

    /// Writes the account's saved posts to a temporary JSON file.
    ///
    /// - Returns: The file URL of the exported JSON, or `nil` if there are no saved posts.
    func export(collection: any ReaderSavedPostsCollectionProtocol) async throws -> URL? {
        try await Self.loadAllPages(of: collection)
        let items = try await collection.loadItems()
        return try Self.writeExportFile(items.map(Self.exportedPost(for:)))
    }

    /// The cache only has the pages the Saved screen has loaded, so the rest are loaded first. A
    /// failure fails the export rather than writing part of the list.
    private static func loadAllPages(of collection: any ReaderSavedPostsCollectionProtocol) async throws {
        // The account keeps at most 1,000 saves, which is 25 pages.
        let maxPages = 50
        var page = try await collection.refresh()
        var pageCount = 1
        while page.hasMore, pageCount < maxPages {
            page = try await collection.loadNextPage()
            pageCount += 1
        }
    }

    /// Saves the posts from an export file in the account. Posts already saved stay as they are.
    ///
    /// - Returns: How many posts were saved, skipped because they're missing the IDs the API
    ///   needs, or failed.
    @MainActor
    static func importPostsToAccount(
        _ posts: [ExportedPost],
        store: ReaderSavedPostsStore
    ) async -> ImportResult {
        do {
            let result = try await store.save(posts.map(identity(for:)))
            return ImportResult(
                imported: result.saved,
                skipped: result.alreadySaved + result.unsaveable,
                failed: result.failed
            )
        } catch {
            Loggers.app.error("Import: saving to the account failed: \(String(describing: error))")
            return ImportResult(imported: 0, skipped: 0, failed: posts.count)
        }
    }

    /// The identity of a post from an export file. It's read like a Core Data post: an RSS item's
    /// post ID is its feed item ID.
    static func identity(for post: ExportedPost) -> ReaderPostSaveIdentity {
        ReaderSavedPostsSync.identity(
            postID: post.postID.map { NSNumber(value: $0) },
            siteID: post.siteID.map { NSNumber(value: $0) },
            feedID: post.feedID.map { NSNumber(value: $0) },
            feedItemID: post.feedItemID.map { NSNumber(value: $0) },
            isExternal: post.isFeed,
            permaLink: post.url
        )
    }

    /// A post from the account's saved list, as an export file has it.
    static func exportedPost(for item: ReaderSavedListItem) -> ExportedPost {
        let post = item.post
        let identity = post?.identity
        let url = identity?.url ?? Self.url(of: item.key) ?? ""

        func positive(_ value: UInt64?) -> UInt? {
            guard let value, value > 0 else { return nil }
            return UInt(value)
        }
        func plainText(_ html: String?) -> String? {
            html.flatMap { ($0 as NSString).makePlainText().nonEmptyString() }
        }

        var siteID = positive(identity?.siteId)
        var postID = positive(identity?.id)
        var feedItemID = positive(identity?.feedItemId)
        var isFeed = identity?.isExternal ?? false
        // A post saved just now has only its key.
        if identity == nil {
            switch item.key {
            case let .post(blogId, postId):
                siteID = positive(blogId)
                postID = postId > 0 ? UInt(postId) : nil
            case let .feedItem(feedItemId):
                feedItemID = positive(feedItemId)
                isFeed = true
            case .url:
                break
            }
        }

        return ExportedPost(
            title: plainText(post?.title) ?? url,
            url: url,
            author: post?.authorName ?? "",
            siteName: post?.siteName ?? "",
            siteURL: post?.siteUrl ?? post?.feedUrl ?? "",
            date: post?.date.map { ISO8601DateFormatter().string(from: $0) },
            summary: plainText(post?.excerpt) ?? "",
            tags: post?.tags.map { $0.compactMap { plainText($0.displayName ?? $0.name) } },
            featuredImageURL: post?.featuredImage?.nonEmptyString(),
            siteID: siteID,
            postID: postID,
            feedID: positive(identity?.feedId),
            feedItemID: feedItemID,
            isFeed: isFeed
        )
    }

    private static func url(of key: ReaderSavedKey) -> String? {
        if case let .url(url) = key { url } else { nil }
    }

    /// Writes the posts to a temporary JSON file.
    ///
    /// - Returns: The file URL of the exported JSON, or `nil` if there are no posts.
    static func writeExportFile(_ exportedPosts: [ExportedPost]) throws -> URL? {
        guard !exportedPosts.isEmpty else { return nil }

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        let envelope = Envelope(
            exportDate: ISO8601DateFormatter().string(from: Date()),
            postCount: exportedPosts.count,
            posts: exportedPosts,
            appVersion: "\(appName) \(appVersion)"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(envelope)

        let filenameDateFormatter = DateFormatter()
        filenameDateFormatter.dateFormat = "yyyy-MM-dd"
        let dateSuffix = filenameDateFormatter.string(from: Date())
        let fileName = "\(appName)-Saved-Posts-\(dateSuffix).json"
        // Each export gets its own folder, so two exports on the same day don't write one file.
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(fileName)
        try data.write(to: fileURL)

        return fileURL
    }

    struct ImportResult {
        let imported: Int
        let skipped: Int
        let failed: Int
    }

    /// Parses the JSON file and returns post entries to import.
    static func parseExportFile(at fileURL: URL) throws -> [ExportedPost] {
        let data = try Data(contentsOf: fileURL)
        do {
            let envelope = try JSONDecoder().decode(Envelope.self, from: data)
            return envelope.posts
        } catch {
            throw ImportError.invalidFormat
        }
    }

    enum ImportError: LocalizedError {
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return NSLocalizedString(
                    "reader.savedPosts.import.invalidFormat",
                    value: "The selected file is not a valid saved posts export.",
                    comment: "Error when the imported file doesn't match the expected JSON format"
                )
            }
        }
    }
}
