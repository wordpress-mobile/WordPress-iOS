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

    @Test func fallbackToFaviconIcon() throws {
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
        #expect(faviconURL.absoluteString == "https://example.com/favicon.icon")
    }

    @Test func fallbackWhenNoFaviconFound() throws {
        // GIVEN
        let siteURL = try #require(URL(string: "https://example.com"))
        let html = "<html><head></head></html>"
        let data = Data(html.utf8)

        // WHEN
        let faviconURL = FaviconService.makeFavicon(from: data, siteURL: siteURL)

        // THEN
        #expect(faviconURL.absoluteString == "https://example.com/favicon.icon")
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
        #expect(faviconURL.absoluteString == "https://example.com/favicon.icon")
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
        #expect(faviconURL.absoluteString == "https://example.com/blog/favicon.icon")
    }

    // MARK: - Fetching

    @Test func retriesAfterFailure() async throws {
        // GIVEN the first lookup fails, for example because the device is offline
        let host = "\(UUID().uuidString.lowercased()).example.com"
        let siteURL = try #require(URL(string: "https://\(host)"))
        let service = FaviconService(session: StubURLProtocol.makeSession())
        StubURLProtocol.setResponse(.failure(URLError(.notConnectedToInternet)), forHost: host)
        await #expect(throws: URLError.self) {
            _ = try await service.favicon(forURL: siteURL)
        }

        // WHEN the device is back online
        let html = #"<html><head><link rel="apple-touch-icon" href="/icon.png"></head></html>"#
        StubURLProtocol.setResponse(.success(Data(html.utf8)), forHost: host)

        // THEN the next lookup finds the icon
        let faviconURL = try await service.favicon(forURL: siteURL)
        #expect(faviconURL.absoluteString == "https://\(host)/icon.png")
        #expect(StubURLProtocol.requestCount(forHost: host) == 2)
    }

    @Test func successfulLookupIsNotRepeated() async throws {
        // GIVEN
        let host = "\(UUID().uuidString.lowercased()).example.com"
        let siteURL = try #require(URL(string: "https://\(host)"))
        let service = FaviconService(session: StubURLProtocol.makeSession())
        let html = #"<html><head><link rel="apple-touch-icon" href="/icon.png"></head></html>"#
        StubURLProtocol.setResponse(.success(Data(html.utf8)), forHost: host)

        // WHEN
        let first = try await service.favicon(forURL: siteURL)
        let second = try await service.favicon(forURL: siteURL)

        // THEN
        #expect(first == second)
        #expect(StubURLProtocol.requestCount(forHost: host) == 1)
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
    }

    private static let hosts = Mutex<[String: Host]>([:])

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func setResponse(_ response: Result<Data, URLError>, forHost host: String) {
        hosts.withLock { $0[host, default: Host(response: response)].response = response }
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
        let response = Self.hosts.withLock { hosts -> Result<Data, URLError> in
            hosts[host, default: Host(response: .failure(URLError(.cannotFindHost)))].requestCount += 1
            return hosts[host]?.response ?? .failure(URLError(.cannotFindHost))
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
