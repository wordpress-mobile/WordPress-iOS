import Foundation
import CoreData
import WordPressData

/// Handles exporting and importing saved Reader posts as JSON files.
struct ReaderSavedPostsExporter {

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

        let postDicts: [[String: Any]] = posts.map { post in
            var dict: [String: Any] = [:]
            dict["title"] = post.titleForDisplay()
            dict["url"] = post.permaLink ?? ""
            dict["author"] = post.authorForDisplay() ?? ""
            dict["siteName"] = post.blogNameForDisplay() ?? ""
            dict["siteURL"] = post.blogURL ?? ""
            if let date = post.dateForDisplay() {
                dict["date"] = dateFormatter.string(from: date)
            }
            dict["summary"] = post.contentPreviewForDisplay() ?? ""
            let tags = post.tagsForDisplay()
            if !tags.isEmpty {
                dict["tags"] = tags
            }
            if let featuredImage = post.featuredImage, !featuredImage.isEmpty {
                dict["featuredImageURL"] = featuredImage
            }
            if let siteID = post.siteID, siteID.intValue > 0 {
                dict["siteID"] = siteID
            }
            if let postID = post.postID, postID.intValue > 0 {
                dict["postID"] = postID
            }
            dict["isFeed"] = post.isExternal
            return dict
        }

        let appName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "WordPress"
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

        var envelope: [String: Any] = [
            "exportDate": dateFormatter.string(from: Date()),
            "postCount": posts.count,
            "posts": postDicts
        ]
        if let appVersion {
            envelope["appVersion"] = "\(appName) \(appVersion)"
        }

        let data = try JSONSerialization.data(withJSONObject: envelope, options: [.prettyPrinted, .sortedKeys])

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
    static func parseExportFile(at fileURL: URL) throws -> [[String: Any]] {
        let data = try Data(contentsOf: fileURL)
        guard let envelope = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let postDicts = envelope["posts"] as? [[String: Any]]
        else {
            throw ImportError.invalidFormat
        }
        return postDicts
    }

    /// Imports saved posts by fetching each one from the API, then marking it as saved.
    /// This ensures posts are created through the normal Core Data pipeline with all required fields.
    ///
    /// - Parameters:
    ///   - postDicts: Parsed post entries from a JSON export file.
    ///   - coreDataStack: The Core Data stack.
    ///   - progress: Called after each post is processed with (completed, total).
    ///   - completion: Called when all posts have been processed.
    static func importPosts(
        _ postDicts: [[String: Any]],
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
            completion(ImportResult(imported: 0, skipped: 0, failed: postDicts.count))
            return
        }

        // Filter to posts that need importing (have siteID + postID, not already saved)
        var toImport: [(siteID: UInt, postID: UInt, isFeed: Bool)] = []
        var skipped = 0

        for dict in postDicts {
            guard let url = dict["url"] as? String, !url.isEmpty else {
                skipped += 1
                continue
            }

            if existingURLs.contains(url) {
                skipped += 1
                continue
            }

            guard let siteID = (dict["siteID"] as? NSNumber)?.uintValue, siteID > 0,
                let postID = (dict["postID"] as? NSNumber)?.uintValue, postID > 0
            else {
                DDLogError("Import: skipping post with missing siteID/postID: \(dict["url"] ?? "unknown")")
                skipped += 1
                continue
            }

            let isFeed = (dict["isFeed"] as? Bool) ?? false
            toImport.append((siteID: siteID, postID: postID, isFeed: isFeed))
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
                            DDLogError("Import: fetchPost returned nil for post \(entry.postID) from site \(entry.siteID)")
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
