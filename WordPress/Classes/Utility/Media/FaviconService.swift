import UIKit

// Fetches URLs for favicons for sites.
actor FaviconService {
    static let shared = FaviconService()

    private nonisolated let cache = FaviconCache()

    private let session = URLSession(configuration: {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        return configuration
    }())

    private var tasks: [URL: FaviconTask] = [:]

    nonisolated func cachedFavicon(forURL siteURL: URL) -> URL? {
        cache.cachedFavicon(forURL: siteURL)
    }

    /// Returns a favicon URL for the given site.
    func favicon(forURL siteURL: URL) async throws -> URL {
        if let faviconURL = cache.cachedFavicon(forURL: siteURL) {
            return faviconURL
        }
        let faviconURL = try await _favicon(forURL: siteURL)
        cache.storeCachedFaviconURL(faviconURL, forURL: siteURL)
        return faviconURL
    }

    private func _favicon(forURL siteURL: URL) async throws -> URL {
        let task = tasks[siteURL] ?? FaviconTask { [session] in
            let (data, response) = try await session.data(from: siteURL)
            try validate(response: response)
            return await makeFavicon(from: data, siteURL: siteURL)
        }
        let subscriptionID = UUID()
        task.subscriptions.insert(subscriptionID)
        tasks[siteURL] = task
        return try await withTaskCancellationHandler {
            try await task.task.value
        } onCancel: {
            Task {
                await self.unsubscribe(subscriptionID, key: siteURL)
            }
        }
    }

    private func unsubscribe(_ subscriptionID: UUID, key: URL) {
        guard let task = tasks[key],
              task.subscriptions.remove(subscriptionID) != nil,
              task.subscriptions.isEmpty else {
            return
        }
        task.task.cancel()
        tasks[key] = nil
    }
}

enum FaviconError: Error {
    case unacceptableStatusCode(_ code: Int)
}

private final class FaviconCache: @unchecked Sendable {
    private let cache = NSCache<AnyObject, AnyObject>()

    func cachedFavicon(forURL siteURL: URL) -> URL? {
        cache.object(forKey: siteURL as NSURL) as? URL
    }

    func storeCachedFaviconURL(_ faviconURL: URL, forURL siteURL: URL) {
        cache.setObject(faviconURL as NSURL, forKey: siteURL as NSURL)
    }
}

private let regex: NSRegularExpression? = {
    let pattern = "<link[^>]*rel=\"apple-touch-icon\"[^>]*href=\"([^\"]+)\"[^>]*>"
    return try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
}()

private func makeFavicon(from data: Data, siteURL: URL) async -> URL {
    let html = String(data: data, encoding: .utf8) ?? ""
    let range = NSRange(location: 0, length: html.utf16.count)
    if let match = regex?.firstMatch(in: html, options: [], range: range),
       let matchRange = Range(match.range(at: 1), in: html),
        let faviconURL = URL(string: String(html[matchRange]), relativeTo: siteURL) {
        return faviconURL
    }
    // Fallback to standard favicon path. It has low quality, but
    // it's better than nothing.
    return siteURL.appendingPathComponent("favicon.icon")
}

private func validate(response: URLResponse) throws {
    guard let response = response as? HTTPURLResponse else {
        return
    }
    guard (200..<300).contains(response.statusCode) else {
        throw FaviconError.unacceptableStatusCode(response.statusCode)
    }
}

private final class FaviconTask {
    var subscriptions = Set<UUID>()
    var isCancelled = false
    var task: Task<URL, Error>

    init(_ closure: @escaping () async throws -> URL) {
        self.task = Task { try await closure() }
    }
}
