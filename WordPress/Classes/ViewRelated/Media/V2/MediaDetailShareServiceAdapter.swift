import Foundation
import UniformTypeIdentifiers
import WordPressData
import WordPressMediaLibrary

@MainActor
final class MediaDetailShareServiceAdapter: MediaDetailShareService {
    private let blog: Blog
    private let authenticator: MediaRequestAuthenticator

    init(
        blog: Blog,
        authenticator: MediaRequestAuthenticator = MediaRequestAuthenticator()
    ) {
        self.blog = blog
        self.authenticator = authenticator
    }

    func downloadForSharing(items: [DownloadableMediaItem]) async throws -> BulkShareDownloadResult {
        guard !items.isEmpty else {
            return BulkShareDownloadResult(urls: [], cleanup: nil)
        }

        let batchDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("media-share-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: batchDir, withIntermediateDirectories: true)

        var usedNames: Set<String> = []
        var result: [URL] = []
        do {
            for item in items {
                try Task.checkCancellation()
                let request = try await authenticator.authenticatedRequest(for: item.sourceUrl, host: MediaHost(blog))
                try Task.checkCancellation()
                let (downloadedURL, response) = try await URLSession.shared.download(for: request)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    // URLSession.download wrote a temp file before we knew the
                    // response code. Clean it up so we don't leak.
                    try? FileManager.default.removeItem(at: downloadedURL)
                    throw URLError(.badServerResponse)
                }

                let filename = Self.uniqueFilename(for: item, against: usedNames)
                usedNames.insert(filename)
                let destination = batchDir.appendingPathComponent(filename)
                do {
                    try FileManager.default.moveItem(at: downloadedURL, to: destination)
                } catch {
                    try? FileManager.default.removeItem(at: downloadedURL)
                    throw error
                }
                result.append(destination)
            }
        } catch {
            try? FileManager.default.removeItem(at: batchDir)
            throw error
        }
        // Cleanup ownership is explicit: the closure captures the batch
        // directory the adapter just created. SharePayload invokes it on
        // activity-sheet dismissal or selection-mode exit; no caller infers
        // ownership from URL paths.
        return BulkShareDownloadResult(
            urls: result,
            cleanup: { try? FileManager.default.removeItem(at: batchDir) }
        )
    }

    static func uniqueFilename(for item: DownloadableMediaItem, against used: Set<String>) -> String {
        let base = resolveFilename(for: item)
        let usedNames = Set(used.map { $0.lowercased() })
        if !usedNames.contains(base.lowercased()) {
            return base
        }

        let stem = (base as NSString).deletingPathExtension
        let ext = (base as NSString).pathExtension
        var counter = 2
        while true {
            let candidate = ext.isEmpty ? "\(stem)-\(counter)" : "\(stem)-\(counter).\(ext)"
            if !usedNames.contains(candidate.lowercased()) {
                return candidate
            }
            counter += 1
        }
    }

    /// Filename derivation (design § Filename derivation):
    /// 1. Start with `suggestedFilename ?? sourceUrl.lastPathComponent`,
    ///    trimmed, with `/` replaced by `-`; empty or dot-only names fall
    ///    back to "media". The module-level helper already screens
    ///    user-controlled title/slug, but this is the final filesystem
    ///    boundary so it screens the URL-last-component fallback path too.
    /// 2. Validate any apparent extension against `mimeType`. A dot segment
    ///    in a human title ("Logo v2.0") is not an extension; only a known
    ///    UTType that agrees with the MIME type counts.
    /// 3. Without a valid extension, derive one from `mimeType` via
    ///    `UTType(mimeType:).preferredFilenameExtension`, falling back to
    ///    the source URL's extension.
    /// 4. Truncate the stem to 200 characters, keeping the extension.
    static func resolveFilename(for item: DownloadableMediaItem) -> String {
        var name = item.suggestedFilename ?? item.sourceUrl.lastPathComponent
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        name = name.replacingOccurrences(of: "/", with: "-")
        if name.isEmpty || name == "." || name == ".." {
            name = "media"
        }

        var stem = (name as NSString).deletingPathExtension
        var ext = (name as NSString).pathExtension
        if !isValidFilenameExtension(ext, forMimeType: item.mimeType) {
            stem = name
            ext = ""
        }
        if ext.isEmpty {
            if let mime = item.mimeType, let resolved = UTType(mimeType: mime)?.preferredFilenameExtension {
                ext = resolved
            } else {
                ext = item.sourceUrl.pathExtension
            }
        }
        if stem.count > 200 {
            stem = String(stem.prefix(200))
        }
        return ext.isEmpty ? stem : "\(stem).\(ext)"
    }

    /// An extension is usable only when UTType recognizes it (unknown
    /// extensions produce dynamic `dyn.*` types, e.g. the "0" in
    /// "Logo v2.0") and it doesn't contradict a known MIME type. The
    /// reverse conformance check keeps real extensions under generic
    /// server MIME types like `application/octet-stream`.
    private static func isValidFilenameExtension(_ ext: String, forMimeType mimeType: String?) -> Bool {
        guard !ext.isEmpty, let extType = UTType(filenameExtension: ext.lowercased()), !extType.isDynamic else {
            return false
        }
        guard let mimeType, let mimeUTType = UTType(mimeType: mimeType), !mimeUTType.isDynamic else {
            return true
        }
        return extType.conforms(to: mimeUTType) || mimeUTType.conforms(to: extType)
    }
}
