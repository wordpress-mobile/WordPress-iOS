import Foundation
import Testing
@testable import WordPressCore
import Synchronization

@Suite final class FaviconServiceTests {
    // MARK: - Picking an icon
    //
    // wordpress-rs tests the HTML parsing and ranking in detail. These check
    // that the service passes the page and its address through.

    @Test func appleTouchIcon() throws {
        let html = #"<html><head><link rel="apple-touch-icon" href="/apple-icon.png"></head></html>"#
        #expect(try favicon(html, pageURL: "https://example.com") == "https://example.com/apple-icon.png")
    }

    @Test func relativePathResolvesAgainstPage() throws {
        let html = #"<link rel="apple-touch-icon" href="assets/icon.png">"#
        #expect(try favicon(html, pageURL: "https://example.com/blog/") == "https://example.com/blog/assets/icon.png")
    }

    @Test func absoluteURL() throws {
        let html = #"<link rel="apple-touch-icon" href="https://cdn.example.com/icon.png">"#
        #expect(try favicon(html, pageURL: "https://example.com") == "https://cdn.example.com/icon.png")
    }

    @Test func picksTheIconClosestToTheIconSize() throws {
        // GIVEN the icons WordPress declares for a site icon
        let html = """
            <link rel="icon" href="https://example.com/cropped-icon-32x32.png" sizes="32x32" />
            <link rel="icon" href="https://example.com/cropped-icon-192x192.png" sizes="192x192" />
            <link rel="apple-touch-icon" href="https://example.com/cropped-icon-180x180.png" />
            <meta name="msapplication-TileImage" content="https://example.com/cropped-icon-270x270.png" />
            """

        // THEN the apple-touch-icon is picked
        #expect(try favicon(html, pageURL: "https://example.com") == "https://example.com/cropped-icon-180x180.png")
    }

    @Test func plainIconWhenThereIsNoAppleTouchIcon() throws {
        let html = #"<link rel="shortcut icon" href="/favicon.png">"#
        #expect(try favicon(html, pageURL: "https://example.com") == "https://example.com/favicon.png")
    }

    @Test func fallsBackToFaviconIcoAtTheRoot() throws {
        // GIVEN a site in a subdirectory that declares no icon
        let html = "<html><head></head></html>"

        // THEN the icon is `/favicon.ico` at the root, where browsers look for it
        #expect(try favicon(html, pageURL: "https://example.com/blog") == "https://example.com/favicon.ico")
    }

    @Test func emptyPageFallsBackToFaviconIco() throws {
        #expect(try favicon("", pageURL: "https://example.com") == "https://example.com/favicon.ico")
    }

    @Test func noIconForAPageThatIsNotOnTheWeb() throws {
        let pageURL = try #require(URL(string: "about:blank"))
        #expect(FaviconService.makeFavicon(from: Data(), pageURL: pageURL) == nil)
    }

    private func favicon(_ html: String, pageURL: String) throws -> String? {
        let pageURL = try #require(URL(string: pageURL))
        return FaviconService.makeFavicon(from: Data(html.utf8), pageURL: pageURL)?.absoluteString
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
