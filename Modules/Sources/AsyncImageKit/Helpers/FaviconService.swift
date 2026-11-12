import Foundation

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
        return makeFavicon(from: data, siteURL: siteURL)
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

    /// Parses HTML data to extract the apple-touch-icon URL or falls back to /favicon.ico
    public static func makeFavicon(from data: Data, siteURL: URL) -> URL {
        let html = String(data: data, encoding: .utf8) ?? ""
        for attributes in linkTagAttributes(in: html) where isAppleTouchIcon(attributes) {
            if let href = attributes["href"], !href.isEmpty,
                let faviconURL = URL(string: href, relativeTo: siteURL)
            {
                return faviconURL
            }
        }
        // Fallback to standard favicon path. It has low quality, but
        // it's better than nothing.
        return siteURL.appendingPathComponent("favicon.ico")
    }
}

public enum FaviconError: Error, Sendable {
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

// MARK: - HTML Parsing

/// Returns whether a `<link>` tag's `rel` names an apple-touch-icon.
private func isAppleTouchIcon(_ attributes: [String: String]) -> Bool {
    let relValues = (attributes["rel"] ?? "").lowercased().split(whereSeparator: \.isWhitespace)
    return relValues.contains("apple-touch-icon") || relValues.contains("apple-touch-icon-precomposed")
}

/// Returns the attributes of every `<link>` tag in `html`, in document order.
///
/// Attribute names are lowercased. Values can be in double quotes, single
/// quotes, or unquoted, and attributes can come in any order.
private func linkTagAttributes(in html: String) -> [[String: String]] {
    var result: [[String: String]] = []
    var remaining = html[...]
    while let tagStart = remaining.range(of: "<link", options: .caseInsensitive) {
        var scanner = TagScanner(text: remaining[tagStart.upperBound...])
        // Skip tags that only start with "link", such as `<linkfoo>`.
        if scanner.isAtAttributeBoundary {
            result.append(scanner.scanAttributes())
        }
        remaining = scanner.remaining
    }
    return result
}

/// Reads the attributes of an HTML tag, up to and including its closing `>`.
private struct TagScanner {
    private let text: Substring
    private var index: Substring.Index

    init(text: Substring) {
        self.text = text
        self.index = text.startIndex
    }

    /// The text after the scanned part.
    var remaining: Substring {
        text[index...]
    }

    var isAtAttributeBoundary: Bool {
        guard let character = current else { return true }
        return character.isWhitespace || character == "/" || character == ">"
    }

    private var current: Character? {
        index < text.endIndex ? text[index] : nil
    }

    mutating func scanAttributes() -> [String: String] {
        var attributes: [String: String] = [:]
        while true {
            skipWhitespace()
            // A `<` starts the next tag, so this one was never closed.
            guard let character = current, character != "<" else { break }
            if character == ">" {
                advance()
                break
            }
            if character == "/" {
                advance()
                continue
            }
            let name = scan { !$0.isWhitespace && $0 != "=" && $0 != ">" && $0 != "/" }.lowercased()
            skipWhitespace()
            var value = ""
            if current == "=" {
                advance()
                skipWhitespace()
                value = scanValue()
            }
            // As in browsers, the first of two attributes with the same name wins.
            if !name.isEmpty, attributes[name] == nil {
                attributes[name] = value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return attributes
    }

    private mutating func scanValue() -> String {
        guard let quote = current, quote == "\"" || quote == "'" else {
            return String(scan { !$0.isWhitespace && $0 != ">" })
        }
        advance()
        let value = scan { $0 != quote && $0 != "<" }
        if current == quote {
            advance()
            return String(value)
        }
        // The quote isn't closed before the next tag. Browsers would read on
        // to the next quote and lose the tags in between. End the value and
        // the tag at the first `>` instead, so the next tag is still read.
        if let end = value.firstIndex(of: ">") {
            index = end
            return String(value[..<end])
        }
        return String(value)
    }

    private mutating func scan(while predicate: (Character) -> Bool) -> Substring {
        let start = index
        while let character = current, predicate(character) {
            advance()
        }
        return text[start..<index]
    }

    private mutating func skipWhitespace() {
        _ = scan { $0.isWhitespace }
    }

    private mutating func advance() {
        if index < text.endIndex {
            index = text.index(after: index)
        }
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
