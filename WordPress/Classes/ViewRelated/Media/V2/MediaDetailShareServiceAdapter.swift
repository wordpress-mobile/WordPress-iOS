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
    /// 1. Start with `suggestedFilename ?? sourceUrl.lastPathComponent`
    /// 2. Sanitize: trim whitespace, replace `/` with `-`, truncate to 200 chars.
    /// 3. If no extension, derive from `mimeType` via
    ///    `UTType(mimeType:).preferredFilenameExtension`.
    static func resolveFilename(for item: DownloadableMediaItem) -> String {
        var name = item.suggestedFilename ?? item.sourceUrl.lastPathComponent
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        name = name.replacingOccurrences(of: "/", with: "-")
        if name.count > 200 { name = String(name.prefix(200)) }
        let ext = (name as NSString).pathExtension
        if ext.isEmpty, let mime = item.mimeType, let resolved = UTType(mimeType: mime)?.preferredFilenameExtension {
            name = "\(name).\(resolved)"
        }
        return name
    }
}
