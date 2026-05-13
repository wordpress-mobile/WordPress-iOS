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
        var isFeed: Bool
    }

    /// Fetches all saved Reader posts and writes them to a temporary JSON file.
    /// - Parameter context: The managed object context to fetch from.
    /// - Returns: The file URL of the exported JSON, or `nil` if there are no saved posts.
    func export(context: NSManagedObjectContext) throws -> URL? {
        let request = NSFetchRequest<ReaderPost>(entityName: ReaderPost.classNameWithoutNamespaces())
        request.predicate = NSPredicate(format: "isSavedForLater == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "sortDate", ascending: false)]

        let posts = try context.fetch(request)
        guard !posts.isEmpty else { return nil }

        let dateFormatter = ISO8601DateFormatter()

        let exportedPosts: [ExportedPost] = posts.map { post in
            let tags = post.tagsForDisplay()
            let featuredImage = post.featuredImage
            let siteID = post.siteID?.uintValue ?? 0
            let postID = post.postID?.uintValue ?? 0

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
                siteID: siteID > 0 ? siteID : nil,
                postID: postID > 0 ? postID : nil,
                isFeed: post.isExternal
            )
        }

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        let envelope = Envelope(
            exportDate: dateFormatter.string(from: Date()),
            postCount: posts.count,
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

    /// Imports saved posts by fetching each one from the API, then marking it as saved.
    /// This ensures posts are created through the normal Core Data pipeline with all required fields.
    ///
    /// - Parameters:
    ///   - posts: Parsed post entries from a JSON export file.
    ///   - coreDataStack: The Core Data stack.
    ///   - progress: Called after each post is processed with (completed, total).
    ///   - completion: Called when all posts have been processed.
    static func importPosts(
        _ posts: [ExportedPost],
        coreDataStack: CoreDataStack,
        progress: @escaping (Int, Int) -> Void,
        completion: @escaping (ImportResult) -> Void
    ) {
        let context = coreDataStack.mainContext

        // Fetch existing saved post URLs for deduplication
        let existingURLs: Set<String>
        do {
            existingURLs = try fetchSavedPostURLs(in: context)
        } catch {
            completion(ImportResult(imported: 0, skipped: 0, failed: posts.count))
            return
        }

        // Filter to posts that need importing (have siteID + postID, not already saved)
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

            guard let siteID = post.siteID, siteID > 0,
                let postID = post.postID, postID > 0
            else {
                DDLogError("Import: skipping post with missing siteID/postID: \(post.url)")
                skipped += 1
                continue
            }

            toImport.append((siteID: siteID, postID: postID, isFeed: post.isFeed))
        }

        guard !toImport.isEmpty else {
            completion(ImportResult(imported: 0, skipped: skipped, failed: 0))
            return
        }

        let total = toImport.count
        let readerPostService = ReaderPostService(coreDataStack: coreDataStack)

        // Process posts sequentially to avoid overwhelming the API with parallel
        // requests. All counter mutations and recursion happen on the main queue
        // so they remain single-threaded regardless of which queue the underlying
        // success/failure callback fires on.
        var imported = 0
        var failed = 0
        var pendingSave = false

        func finish() {
            if pendingSave {
                coreDataStack.save(context)
            }
            completion(ImportResult(imported: imported, skipped: skipped, failed: failed))
        }

        func fetchNext(index: Int) {
            guard index < toImport.count else {
                finish()
                return
            }

            let entry = toImport[index]
            readerPostService.fetchPost(
                entry.postID,
                forSite: entry.siteID,
                isFeed: entry.isFeed,
                success: { post in
                    DispatchQueue.main.async {
                        if let post {
                            if !post.isSavedForLater {
                                post.isSavedForLater = true
                                pendingSave = true
                            }
                            imported += 1
                        } else {
                            DDLogError(
                                "Import: fetchPost returned nil for post \(entry.postID) from site \(entry.siteID)"
                            )
                            failed += 1
                        }
                        progress(index + 1, total)
                        fetchNext(index: index + 1)
                    }
                },
                failure: { error in
                    DispatchQueue.main.async {
                        DDLogError(
                            "Import: failed to fetch post \(entry.postID) from site \(entry.siteID): \(String(describing: error))"
                        )
                        failed += 1
                        progress(index + 1, total)
                        fetchNext(index: index + 1)
                    }
                }
            )
        }

        fetchNext(index: 0)
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
