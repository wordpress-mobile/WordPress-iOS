import Foundation
import CoreData
import WordPressData

/// Handles exporting and importing saved Reader posts as JSON files.
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

    /// Fetches all saved Reader posts and writes them to a temporary JSON file.
    ///
    /// The Core Data fetch, JSON encoding, and file write all run off the main
    /// thread so a large export doesn't block the UI.
    ///
    /// - Parameter coreDataStack: The Core Data stack.
    /// - Returns: The file URL of the exported JSON, or `nil` if there are no saved posts.
    func export(coreDataStack: CoreDataStackSwift) async throws -> URL? {
        // Do the Core Data work on a background context and only return value
        // types (no managed objects escape the closure).
        let exportedPosts: [ExportedPost] = try await coreDataStack.performQuery { context in
            let request = NSFetchRequest<ReaderPost>(entityName: ReaderPost.classNameWithoutNamespaces())
            request.predicate = NSPredicate(format: "isSavedForLater == YES")
            request.sortDescriptors = [NSSortDescriptor(key: "sortDate", ascending: false)]

            let posts = try context.fetch(request)
            let dateFormatter = ISO8601DateFormatter()

            return posts.map { post in
                let tags = post.tagsForDisplay()
                let featuredImage = post.featuredImage

                // Use int64Value (not uintValue) so the inherited BasePost.postID default
                // of -1 isn't reinterpreted as UInt.max and exported as a valid ID.
                func positiveUInt(_ number: NSNumber?) -> UInt? {
                    guard let value = number?.int64Value, value > 0 else { return nil }
                    return UInt(value)
                }

                return ExportedPost(
                    title: post.titleForDisplay(),
                    url: post.permaLink ?? "",
                    author: post.authorForDisplay() ?? "",
                    siteName: post.blogNameForDisplay() ?? "",
                    siteURL: post.blogURL ?? "",
                    date: post.dateForDisplay().map { dateFormatter.string(from: $0) },
                    summary: post.contentPreviewForDisplay() ?? "",
                    tags: tags.isEmpty ? nil : tags,
                    featuredImageURL: (featuredImage?.isEmpty ?? true) ? nil : featuredImage,
                    siteID: positiveUInt(post.siteID),
                    postID: positiveUInt(post.postID),
                    feedID: positiveUInt(post.feedID),
                    feedItemID: positiveUInt(post.feedItemID),
                    isFeed: post.isExternal
                )
            }
        }

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
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
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

    /// The maximum number of posts to fetch from the API at the same time.
    ///
    /// Imports run in parallel for speed, but the concurrency is bounded so a
    /// large export file doesn't overwhelm the API with requests.
    private static let maxConcurrentImports = 4

    /// Imports saved posts by fetching each one from the API, then marking it as saved.
    /// This ensures posts are created through the normal Core Data pipeline with all required fields.
    ///
    /// - Parameters:
    ///   - posts: Parsed post entries from a JSON export file.
    ///   - coreDataStack: The Core Data stack.
    ///   - progress: Updated as posts are processed so callers can surface import progress.
    /// - Returns: A summary of how many posts were imported, skipped, or failed.
    static func importPosts(
        _ posts: [ExportedPost],
        coreDataStack: CoreDataStackSwift,
        progress: Progress
    ) async -> ImportResult {
        // Fetch existing saved post URLs for deduplication.
        let existingURLs: Set<String>
        do {
            existingURLs = try await coreDataStack.performQuery { context in
                try fetchSavedPostURLs(in: context)
            }
        } catch {
            return ImportResult(imported: 0, skipped: 0, failed: posts.count)
        }

        // Filter to posts that need importing (have usable identifiers, not already saved).
        // Feed posts identify themselves with feedID/feedItemID; site posts use siteID/postID.
        var toImport: [(siteID: UInt, postID: UInt, isFeed: Bool)] = []
        var skipped = 0

        for post in posts {
            guard !post.url.isEmpty else {
                skipped += 1
                continue
            }

            if existingURLs.contains(post.url) {
                skipped += 1
                continue
            }

            let siteIdentifier: UInt?
            let postIdentifier: UInt?
            if post.isFeed {
                siteIdentifier = post.feedID
                postIdentifier = post.feedItemID
            } else {
                siteIdentifier = post.siteID
                postIdentifier = post.postID
            }

            guard let siteID = siteIdentifier, siteID > 0,
                let postID = postIdentifier, postID > 0
            else {
                Loggers.app.error("Import: skipping post with missing identifiers: \(post.url)")
                skipped += 1
                continue
            }

            toImport.append((siteID: siteID, postID: postID, isFeed: post.isFeed))
        }

        guard !toImport.isEmpty else {
            return ImportResult(imported: 0, skipped: skipped, failed: 0)
        }

        progress.totalUnitCount = Int64(toImport.count)
        progress.completedUnitCount = 0

        let service = ReaderPostService(coreDataStack: coreDataStack)

        var imported = 0
        var failed = 0

        // Import posts in parallel, but bound the concurrency so we don't flood
        // the API. Counter and progress mutations happen here in the parent task
        // as each child task finishes, so they stay single-threaded.
        await withTaskGroup(of: Bool.self) { group in
            var iterator = toImport.makeIterator()

            func addNextTask() {
                guard let entry = iterator.next() else { return }
                group.addTask {
                    await importPost(
                        siteID: entry.siteID,
                        postID: entry.postID,
                        isFeed: entry.isFeed,
                        service: service,
                        coreDataStack: coreDataStack
                    )
                }
            }

            for _ in 0..<maxConcurrentImports {
                addNextTask()
            }

            while let didImport = await group.next() {
                if didImport {
                    imported += 1
                } else {
                    failed += 1
                }
                progress.completedUnitCount += 1
                addNextTask()
            }
        }

        return ImportResult(imported: imported, skipped: skipped, failed: failed)
    }

    /// Fetches a single post from the API and marks it as saved.
    /// - Returns: `true` if the post was imported, `false` if it couldn't be fetched.
    private static func importPost(
        siteID: UInt,
        postID: UInt,
        isFeed: Bool,
        service: ReaderPostService,
        coreDataStack: CoreDataStackSwift
    ) async -> Bool {
        do {
            let postID = try await fetchPost(
                siteID: siteID,
                postID: postID,
                isFeed: isFeed,
                service: service
            )
            try await coreDataStack.performAndSave { [postID] context in
                let post = try context.existingObject(with: postID)
                if !post.isSavedForLater {
                    post.isSavedForLater = true
                }
            }
            return true
        } catch {
            Loggers.app.error(
                "Import: failed to fetch post \(postID) from site \(siteID): \(String(describing: error))"
            )
            return false
        }
    }

    /// Wraps `ReaderPostService.fetchPost` as an async call, returning the
    /// typed object ID of the fetched post.
    private static func fetchPost(
        siteID: UInt,
        postID: UInt,
        isFeed: Bool,
        service: ReaderPostService
    ) async throws -> TaggedManagedObjectID<ReaderPost> {
        try await withCheckedThrowingContinuation { continuation in
            service.fetchPost(
                postID,
                forSite: siteID,
                isFeed: isFeed,
                success: { post in
                    if let post {
                        continuation.resume(returning: TaggedManagedObjectID(post))
                    } else {
                        continuation.resume(throwing: ImportError.postUnavailable)
                    }
                },
                failure: { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: ImportError.postUnavailable)
                    }
                }
            )
        }
    }

    private static func fetchSavedPostURLs(in context: NSManagedObjectContext) throws -> Set<String> {
        let request = NSFetchRequest<ReaderPost>(entityName: ReaderPost.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "isSavedForLater == YES")
        request.propertiesToFetch = ["permaLink"]

        let posts = try context.fetch(request)
        return Set(posts.compactMap(\.permaLink))
    }

    enum ImportError: LocalizedError {
        case invalidFormat
        case postUnavailable

        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return NSLocalizedString(
                    "reader.savedPosts.import.invalidFormat",
                    value: "The selected file is not a valid saved posts export.",
                    comment: "Error when the imported file doesn't match the expected JSON format"
                )
            case .postUnavailable:
                return nil
            }
        }
    }
}
