import Foundation
import WordPressAPI

/// Fetches URLs for favicons for sites.
public actor FaviconService {
    public static let shared = FaviconService()

    private nonisolated let cache = FaviconCache()

    private let session: URLSession
    private let retryDelay: TimeInterval
    private let now: @Sendable () -> Date

    /// Lookups that are in flight, shared by everyone who asks for the same site.
    private var tasks: [URL: FaviconTask] = [:]

    /// Recent failed lookups. A site is looked up again only after
    /// `retryDelay`, so a site that keeps failing isn't downloaded every time
    /// one of its posts is shown.
    private var failures: [URL: Failure] = [:]

    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        self.init(session: URLSession(configuration: configuration))
    }

    init(
        session: URLSession,
        retryDelay: TimeInterval = 60,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.session = session
        self.retryDelay = retryDelay
        self.now = now
    }

    nonisolated public func cachedFavicon(forURL siteURL: URL) -> URL? {
        cache.cachedFavicon(forURL: siteURL)
    }

    /// Returns a favicon URL for the given site.
    public func favicon(forURL siteURL: URL) async throws -> URL {
        if let faviconURL = cache.cachedFavicon(forURL: siteURL) {
            return faviconURL
        }
        if let failure = failures[siteURL], now().timeIntervalSince(failure.date) < retryDelay {
            throw failure.error
        }
        let task = tasks[siteURL] ?? makeTask(for: siteURL)
        let subscriptionID = UUID()
        task.subscriptions.insert(subscriptionID)
        return try await withTaskCancellationHandler {
            try await task.task.value
        } onCancel: {
            Task {
                await self.unsubscribe(subscriptionID, key: siteURL)
            }
        }
    }

    private func makeTask(for siteURL: URL) -> FaviconTask {
        let id = UUID()
        let task = FaviconTask(id: id, task: Task { try await self.lookUpFavicon(forURL: siteURL, id: id) })
        tasks[siteURL] = task
        return task
    }

    /// Downloads the site's homepage and records the result.
    ///
    /// The result is recorded in the same step that removes the finished task,
    /// so a later call finds either the task, the cached favicon or the failure.
    private func lookUpFavicon(forURL siteURL: URL, id: UUID) async throws -> URL {
        defer {
            // Check that `tasks` still holds this task, so that a newer one
            // is left alone.
            if tasks[siteURL]?.id == id {
                tasks[siteURL] = nil
            }
        }
        do {
            let faviconURL = try await Self.downloadFavicon(forURL: siteURL, session: session)
            cache.storeCachedFaviconURL(faviconURL, forURL: siteURL)
            failures[siteURL] = nil
            return faviconURL
        } catch {
            if !Task.isCancelled {
                failures[siteURL] = Failure(date: now(), error: error)
            }
            throw error
        }
    }

    private nonisolated static func downloadFavicon(forURL siteURL: URL, session: URLSession) async throws -> URL {
        let (data, response) = try await session.data(from: siteURL)
        try validate(response: response)
        // Relative icon addresses resolve against the page's final address, after redirects.
        let pageURL = response.url ?? siteURL
        guard let faviconURL = makeFavicon(from: data, pageURL: pageURL) else {
            throw FaviconError.noIcon
        }
        return faviconURL
    }

    private func unsubscribe(_ subscriptionID: UUID, key: URL) {
        guard let task = tasks[key],
            task.subscriptions.remove(subscriptionID) != nil,
            task.subscriptions.isEmpty
        else {
            return
        }
        task.task.cancel()
        tasks[key] = nil
    }

    /// The icon in a page's HTML that best fits `preferredIconSize`, or
    /// `/favicon.ico` at the root of the page's origin when it declares none.
    ///
    /// Returns `nil` when the page declares no icon and isn't on `http` or
    /// `https`, so there is no `/favicon.ico` to fall back to.
    static func makeFavicon(from data: Data, pageURL: URL) -> URL? {
        let html = String(decoding: data, as: UTF8.self)
        let icon = try? SiteIcon.preferred(inHTML: html, pageURL: pageURL, size: preferredIconSize)
        return icon?.asURL
    }

    /// The size, in pixels, of the icon to pick from the ones a page declares.
    ///
    /// 180 pixels is the size of a standard `apple-touch-icon`, which is
    /// square and opaque, and is what the app picked before it ranked icons
    /// by size. It's sharp at the 28 and 40 point sizes the Reader shows site
    /// icons at, on a 3x screen.
    static let preferredIconSize: UInt32 = 180
}

public enum FaviconError: Error, Sendable {
    case unacceptableStatusCode(_ code: Int)
    /// The page declares no icon, and isn't on `http` or `https`.
    case noIcon
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

private func validate(response: URLResponse) throws {
    guard let response = response as? HTTPURLResponse else {
        return
    }
    guard (200..<300).contains(response.statusCode) else {
        throw FaviconError.unacceptableStatusCode(response.statusCode)
    }
}

private final class FaviconTask {
    let id: UUID
    let task: Task<URL, Error>
    var subscriptions = Set<UUID>()

    init(id: UUID, task: Task<URL, Error>) {
        self.id = id
        self.task = task
    }
}

private struct Failure {
    let date: Date
    let error: Error
}
