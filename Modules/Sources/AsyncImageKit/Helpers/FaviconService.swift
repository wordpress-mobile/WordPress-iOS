import Foundation

/// Fetches URLs for favicons for sites.
public actor FaviconService {
    public static let shared = FaviconService()

    private nonisolated let cache = FaviconCache()

    private let session: URLSession

    private var tasks: [URL: FaviconTask] = [:]

    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        self.init(session: URLSession(configuration: configuration))
    }

    init(session: URLSession) {
        self.session = session
    }

    nonisolated public func cachedFavicon(forURL siteURL: URL) -> URL? {
        cache.cachedFavicon(forURL: siteURL)
    }

    /// Returns a favicon URL for the given site.
    public func favicon(forURL siteURL: URL) async throws -> URL {
        if let faviconURL = cache.cachedFavicon(forURL: siteURL) {
            return faviconURL
        }
        let faviconURL = try await _favicon(forURL: siteURL)
        cache.storeCachedFaviconURL(faviconURL, forURL: siteURL)
        return faviconURL
    }

    private func _favicon(forURL siteURL: URL) async throws -> URL {
        let task =
            tasks[siteURL]
            ?? FaviconTask { [session] in
                let (data, response) = try await session.data(from: siteURL)
                try validate(response: response)
                return FaviconService.makeFavicon(from: data, siteURL: siteURL)
            }
        let subscriptionID = UUID()
        task.subscriptions.insert(subscriptionID)
        tasks[siteURL] = task
        do {
            return try await withTaskCancellationHandler {
                try await task.task.value
            } onCancel: {
                Task {
                    await self.unsubscribe(subscriptionID, key: siteURL)
                }
            }
        } catch {
            // Forget a failed lookup so that the next call tries again. A
            // successful one stays in `tasks`, so it isn't repeated. Check that
            // `tasks` still holds this task, so that a newer one is left alone.
            if tasks[siteURL] === task {
                tasks[siteURL] = nil
            }
            throw error
        }
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
            guard let character = current else { break }
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
        let value = scan { $0 != quote }
        advance() // the closing quote
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
    var subscriptions = Set<UUID>()
    var isCancelled = false
    var task: Task<URL, Error>

    init(_ closure: @escaping @Sendable () async throws -> URL) {
        self.task = Task { try await closure() }
    }
}
