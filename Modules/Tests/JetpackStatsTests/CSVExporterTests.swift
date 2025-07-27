import Foundation
import Testing
@testable import JetpackStats

struct CSVExporterTests {

    @Test("CSV export generates correct headers and data for posts")
    func testCSVExportForPosts() {
        // Given
        let posts: [TopListItem.Post] = [
            TopListItem.Post(
                title: "My First Post",
                postID: "123",
                postURL: URL(string: "https://example.com/post1"),
                date: Date(timeIntervalSince1970: 1700000000), // Nov 14, 2023
                type: "post",
                author: "John Doe",
                metrics: SiteMetricsSet(views: 150, visitors: 100, likes: 10, comments: 5)
            ),
            TopListItem.Post(
                title: "Another Post, With Comma",
                postID: "124",
                postURL: URL(string: "https://example.com/post2"),
                date: Date(timeIntervalSince1970: 1700100000), // Nov 15, 2023
                type: "page",
                author: "Jane \"The Writer\" Smith",
                metrics: SiteMetricsSet(views: 300, visitors: 250, likes: 20, comments: 15)
            ),
            TopListItem.Post(
                title: "Post with\nNewline",
                postID: "125",
                postURL: nil,
                date: nil,
                type: nil,
                author: nil,
                metrics: SiteMetricsSet(views: 50, visitors: 40, likes: 2, comments: 1)
            )
        ]

        let exporter = CSVExporter()
        let metric = SiteMetric.views

        // When
        let csv = exporter.generateCSV(from: posts, metric: metric)

        // Then
        let lines = csv.split(separator: "\r\n").map(String.init)

        // Verify we have header + 3 data rows
        #expect(lines.count == 4)

        // Verify headers
        let expectedHeaders = [
            Strings.CSVExport.title,
            Strings.CSVExport.url,
            Strings.CSVExport.date,
            Strings.CSVExport.type,
            SiteMetric.views.localizedTitle // The metric's localized title
        ].joined(separator: ",")
        #expect(lines[0] == expectedHeaders)

        // Verify first post data
        #expect(lines[1].contains("My First Post"))
        #expect(lines[1].contains("https://example.com/post1"))
        #expect(lines[1].contains("post"))
        #expect(lines[1].contains("150")) // views count

        // Verify second post data with special characters
        #expect(lines[2].contains("\"Another Post, With Comma\"")) // Comma should be escaped
        #expect(lines[2].contains("page")) // type
        #expect(lines[2].contains("300")) // views count
    }

    @Test("CSV export handles different metrics correctly")
    func testCSVExportWithDifferentMetrics() {
        // Given
        let post = TopListItem.Post(
            title: "Test Post",
            postID: "1",
            postURL: URL(string: "https://example.com/test"),
            date: Date(),
            type: "post",
            author: "Test Author",
            metrics: SiteMetricsSet(
                views: 100,
                visitors: 80,
                likes: 20,
                comments: 10,
                posts: 1,
                bounceRate: 45,
                timeOnSite: 120,
                downloads: 5
            )
        )

        let exporter = CSVExporter()

        // Test with different metrics
        let metricsToTest: [(SiteMetric, Int?)] = [
            (.views, 100),
            (.visitors, 80),
            (.likes, 20),
            (.comments, 10),
            (.bounceRate, 45),
            (.timeOnSite, 120),
            (.downloads, 5)
        ]

        for (metric, expectedValue) in metricsToTest {
            // When
            let csv = exporter.generateCSV(from: [post], metric: metric)
            let lines = csv.split(separator: "\r\n").map(String.init)

            // Then
            #expect(lines.count == 2) // Header + 1 data row
            #expect(lines[0].contains(metric.localizedTitle))
            #expect(lines[1].contains("\(expectedValue ?? 0)"))
        }
    }

    @Test("CSV export handles empty array")
    func testCSVExportWithEmptyArray() {
        // Given
        let exporter = CSVExporter()
        let posts: [TopListItem.Post] = []

        // When
        let csv = exporter.generateCSV(from: posts, metric: .views)

        // Then
        #expect(csv.isEmpty)
    }

    @Test("CSV uses RFC 4180 compliant line endings")
    func testCSVLineEndings() {
        // Given
        let posts: [TopListItem.Post] = [
            TopListItem.Post(
                title: "Post 1",
                postID: "1",
                postURL: nil,
                date: nil,
                type: nil,
                author: nil,
                metrics: SiteMetricsSet(views: 1)
            ),
            TopListItem.Post(
                title: "Post 2",
                postID: "2",
                postURL: nil,
                date: nil,
                type: nil,
                author: nil,
                metrics: SiteMetricsSet(views: 2)
            )
        ]

        let exporter = CSVExporter()

        // When
        let csv = exporter.generateCSV(from: posts, metric: .views)

        // Then
        // Verify CRLF line endings are used (RFC 4180 standard)
        #expect(csv.contains("\r\n"))
        #expect(!csv.contains("\n\r")) // Wrong order

        // Verify we have exactly 2 CRLF sequences (after header and first data row)
        let crlfCount = csv.components(separatedBy: "\r\n").count - 1
        #expect(crlfCount == 2)
    }
}
