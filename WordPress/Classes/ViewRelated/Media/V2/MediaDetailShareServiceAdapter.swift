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

    func downloadForSharing(items: [DownloadableMediaItem]) async throws -> [URL] {
        var result: [URL] = []
        for item in items {
            let request = try await authenticator.authenticatedRequest(for: item.sourceUrl, host: MediaHost(blog))
            let (downloadedURL, response) = try await URLSession.shared.download(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                // URLSession.download wrote a temp file before we knew the
                // response code. Clean it up so we don't leak.
                try? FileManager.default.removeItem(at: downloadedURL)
                throw URLError(.badServerResponse)
            }
            let url = try moveDownloadedFile(at: downloadedURL, item: item)
            result.append(url)
        }
        return result
    }

    private func moveDownloadedFile(at source: URL, item: DownloadableMediaItem) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
        let filename = Self.resolveFilename(for: item)
        let destination = dir.appendingPathComponent(filename)
        // Replace any prior temp file at the destination so the share path
        // is idempotent within a session.
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: source, to: destination)
        return destination
    }

    /// Filename derivation (design § Filename derivation):
    /// 1. Start with `suggestedFilename ?? sourceUrl.lastPathComponent`,
    ///    trimmed, with `/` replaced by `-`; empty or dot-only names fall
    ///    back to "media".
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
