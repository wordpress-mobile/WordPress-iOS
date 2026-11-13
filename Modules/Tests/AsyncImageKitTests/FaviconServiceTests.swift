import Foundation
import Testing
@testable import AsyncImageKit
import Synchronization

@Suite final class FaviconServiceTests {
    @Test func appleTouchIcon() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link rel="apple-touch-icon" href="/apple-icon.png">
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/apple-icon.png")
    }

    @Test func appleTouchIconPrecomposed() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link rel="apple-touch-icon-precomposed" href="/apple-icon-precomposed.png">
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/apple-icon-precomposed.png")
    }

    @Test func appleTouchIconWithAbsoluteURL() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link rel="apple-touch-icon" href="https://cdn.example.com/icon.png">
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://cdn.example.com/icon.png")
    }

    @Test func appleTouchIconWithRelativePath() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link rel="apple-touch-icon" href="assets/icon.png">
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/assets/icon.png")
    }

    @Test func appleTouchIconWithAdditionalAttributes() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link rel="apple-touch-icon" sizes="180x180" href="/apple-icon-180x180.png">
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/apple-icon-180x180.png")
    }

    @Test func appleTouchIconPrecomposedWithSizes() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link rel="apple-touch-icon-precomposed" sizes="152x152" href="/apple-icon-precomposed-152.png">
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/apple-icon-precomposed-152.png")
    }

    @Test func fallbackToFaviconIco() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link rel="icon" href="/favicon.ico">
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/favicon.ico")
    }

    @Test func fallbackWhenNoFaviconFound() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = "<html><head></head></html>"
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/favicon.ico")
    }

    @Test func appleTouchIconCaseInsensitive() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link rel="APPLE-TOUCH-ICON" href="/apple-icon.png">
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/apple-icon.png")
    }

    @Test func multipleAppleTouchIconsUsesFirst() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link rel="apple-touch-icon" sizes="180x180" href="/apple-icon-180.png">
                <link rel="apple-touch-icon" sizes="152x152" href="/apple-icon-152.png">
                <link rel="apple-touch-icon-precomposed" href="/apple-icon-precomposed.png">
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN - Uses the first match
        #expect(faviconURL.absoluteString == "https://example.com/apple-icon-180.png")
    }

    @Test func emptyData() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let data = Data()

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN - Falls back to standard favicon path
        #expect(faviconURL.absoluteString == "https://example.com/favicon.ico")
    }

    @Test func siteURLWithPath() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com/blog"))
        let html = """
            <html>
            <head>
                <link rel="apple-touch-icon" href="/apple-icon.png">
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/apple-icon.png")
    }

    @Test func siteURLWithPathFallback() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com/blog"))
        let html = "<html><head></head></html>"
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/blog/favicon.ico")
    }

    @Test func appleTouchIconWithHrefBeforeRel() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link href="/apple-icon.png" rel="apple-touch-icon">
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/apple-icon.png")
    }

    @Test func appleTouchIconWithSingleQuotes() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link rel='apple-touch-icon' href='/apple-icon.png'>
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/apple-icon.png")
    }

    @Test func appleTouchIconWithUnquotedAttributesAndOtherRelTokens() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link rel="stylesheet" href="/style.css">
                <LINK HREF=/apple-icon.png REL="icon apple-touch-icon" />
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/apple-icon.png")
    }

    @Test func appleTouchIconWithAngleBracketInOtherAttribute() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link title="a > b" rel="apple-touch-icon" href="/apple-icon.png">
            </head>
            </html>
            """
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/apple-icon.png")
    }

    @Test func appleTouchIconAfterUnclosedQuote() throws {
        // GIVEN a tag before the icon whose quote is never closed
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <html>
            <head>
                <link rel="preload" href="/font.woff2>
                <link rel="apple-touch-icon" href="/icon.png">
            </head>
            </html>
            """

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: Data(html.utf8), siteURL: siteURL)

        // THEN the icon tag is still read
        #expect(faviconURL.absoluteString == "https://example.com/icon.png")
    }

    @Test func appleTouchIconAfterUnclosedTag() throws {
        // GIVEN a tag before the icon with no closing `>`
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = """
            <link rel="preload" href="/font.woff2"
            <link rel="apple-touch-icon" href="/icon.png">
            """

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: Data(html.utf8), siteURL: siteURL)

        // THEN the icon tag is still read
        #expect(faviconURL.absoluteString == "https://example.com/icon.png")
    }

    // MARK: - Fetching

    @Test func retriesAfterFailure() async throws {
        // GIVEN the first lookup fails, for example because the device is offline
        let host = "\(UUID().uuidString.lowercased()).example.com"
        let siteURL = try #require(URL(string: "https://\(host)"))
        let clock = TestClock()
        let service = FaviconService(session: StubURLProtocol.makeSession(), retryDelay: 60, now: clock.now)
        StubURLProtocol.setResponse(.failure(URLError(.notConnectedToInternet)), forHost: host)
        await #expect(throws: URLError.self) {
            _ = try await service.favicon(forURL: siteURL)
        }

        // WHEN the device is back online after the retry delay
        let html = #"<html><head><link rel="apple-touch-icon" href="/icon.png"></head></html>"#
        StubURLProtocol.setResponse(.success(Data(html.utf8)), forHost: host)
        clock.advance(by: 61)

        // THEN the next lookup finds the icon
        let faviconURL = try await service.favicon(forURL: siteURL)
        #expect(faviconURL.absoluteString == "https://\(host)/icon.png")
        #expect(StubURLProtocol.requestCount(forHost: host) == 2)
    }

    @Test func failingSiteIsNotLookedUpAgainBeforeRetryDelay() async throws {
        // GIVEN a site that always fails, for example because its domain is gone
        let host = "\(UUID().uuidString.lowercased()).example.com"
        let siteURL = try #require(URL(string: "https://\(host)"))
        let clock = TestClock()
        let service = FaviconService(session: StubURLProtocol.makeSession(), retryDelay: 60, now: clock.now)
        StubURLProtocol.setResponse(.failure(URLError(.cannotFindHost)), forHost: host)

        // WHEN its posts are shown 10 times within the retry delay
        for _ in 0..<10 {
            await #expect(throws: URLError.self) {
                _ = try await service.favicon(forURL: siteURL)
            }
            clock.advance(by: 5)
        }

        // THEN its homepage is downloaded once
        #expect(StubURLProtocol.requestCount(forHost: host) == 1)
    }

    @Test func concurrentLookupsShareOneRequest() async throws {
        // GIVEN a slow site
        let host = "\(UUID().uuidString.lowercased()).example.com"
        let siteURL = try #require(URL(string: "https://\(host)"))
        let service = FaviconService(session: StubURLProtocol.makeSession())
        let html = #"<html><head><link rel="apple-touch-icon" href="/icon.png"></head></html>"#
        StubURLProtocol.setResponse(.success(Data(html.utf8)), forHost: host, delay: 0.2)

        // WHEN several of its posts are shown at once
        let faviconURLs = try await withThrowingTaskGroup(of: URL.self) { group in
            for _ in 0..<5 {
                group.addTask { try await service.favicon(forURL: siteURL) }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        // THEN its homepage is downloaded once
        #expect(faviconURLs.allSatisfy { $0.absoluteString == "https://\(host)/icon.png" })
        #expect(StubURLProtocol.requestCount(forHost: host) == 1)
    }

    @Test func cancelledLookupIsNotRememberedAsFailure() async throws {
        // GIVEN a lookup that is cancelled before the slow site answers
        let host = "\(UUID().uuidString.lowercased()).example.com"
        let siteURL = try #require(URL(string: "https://\(host)"))
        let service = FaviconService(session: StubURLProtocol.makeSession())
        let html = #"<html><head><link rel="apple-touch-icon" href="/icon.png"></head></html>"#
        StubURLProtocol.setResponse(.success(Data(html.utf8)), forHost: host, delay: 0.5)
        let task = Task { try await service.favicon(forURL: siteURL) }
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        _ = try? await task.value

        // WHEN the site is asked for again
        StubURLProtocol.setResponse(.success(Data(html.utf8)), forHost: host)
        let faviconURL = try await service.favicon(forURL: siteURL)

        // THEN it is looked up again instead of failing
        #expect(faviconURL.absoluteString == "https://\(host)/icon.png")
    }

    @Test func concurrentFailuresAndCancellationsRecover() async throws {
        let html = #"<html><head><link rel="apple-touch-icon" href="/icon.png"></head></html>"#
        for _ in 0..<20 {
            // GIVEN many overlapping lookups of a failing site, some cancelled
            let host = "\(UUID().uuidString.lowercased()).example.com"
            let siteURL = try #require(URL(string: "https://\(host)"))
            let service = FaviconService(session: StubURLProtocol.makeSession(), retryDelay: 0)
            StubURLProtocol.setResponse(.failure(URLError(.timedOut)), forHost: host, delay: 0.01)
            await withTaskGroup(of: Void.self) { group in
                for index in 0..<12 {
                    group.addTask {
                        try? await Task.sleep(for: .milliseconds(Int.random(in: 0...12)))
                        let task = Task { _ = try? await service.favicon(forURL: siteURL) }
                        if index % 3 == 0 {
                            try? await Task.sleep(for: .milliseconds(Int.random(in: 0...12)))
                            task.cancel()
                        }
                        await task.value
                    }
                }
            }

            // WHEN the site starts working
            StubURLProtocol.setResponse(.success(Data(html.utf8)), forHost: host)

            // THEN the next lookup finds the icon
            let faviconURL = try await service.favicon(forURL: siteURL)
            #expect(faviconURL.absoluteString == "https://\(host)/icon.png")
        }
    }
}

/// A clock that tests move forward by hand.
private final class TestClock: Sendable {
    private let date = Mutex(Date(timeIntervalSince1970: 0))

    var now: @Sendable () -> Date {
        { self.date.withLock { $0 } }
    }

    func advance(by interval: TimeInterval) {
        date.withLock { $0 += interval }
    }
}

/// Serves canned responses by host to a session made with `makeSession()`.
///
/// It is used instead of the global OHHTTPStubs stubs, which other suites in
/// this target replace and remove while they run in parallel with this one.
private final class StubURLProtocol: URLProtocol {
    private struct Host {
        var response: Result<Data, URLError>
        var requestCount = 0
        var delay: TimeInterval = 0
    }

    private static let hosts = Mutex<[String: Host]>([:])

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func setResponse(_ response: Result<Data, URLError>, forHost host: String, delay: TimeInterval = 0) {
        hosts.withLock {
            $0[host, default: Host(response: response)].response = response
            $0[host]?.delay = delay
        }
    }

    static func requestCount(forHost host: String) -> Int {
        hosts.withLock { $0[host]?.requestCount ?? 0 }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url, let host = url.host() else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let (response, delay) = Self.hosts.withLock { hosts -> (Result<Data, URLError>, TimeInterval) in
            hosts[host, default: Host(response: .failure(URLError(.cannotFindHost)))].requestCount += 1
            return (hosts[host]?.response ?? .failure(URLError(.cannotFindHost)), hosts[host]?.delay ?? 0)
        }
        if delay > 0 {
            Thread.sleep(forTimeInterval: delay)
        }
        switch response {
        case .success(let data):
            let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            if let httpResponse {
                client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
