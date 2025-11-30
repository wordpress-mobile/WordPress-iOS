import UIKit
import Testing
import AsyncImageKit

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
}
