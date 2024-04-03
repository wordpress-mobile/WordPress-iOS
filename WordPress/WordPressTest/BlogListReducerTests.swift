import XCTest
@testable import WordPress

final class BlogListReducerTests: XCTestCase {
    private enum Constants {
        static let jsonEncoder = JSONEncoder()
        static let jsonDecoder = JSONDecoder()
    }

    private let repository = InMemoryUserDefaults()
    private static let suiteName = "TestSuite_BlogListReducerTests"

    // MARK: - Helper Methods
    private func encodeAndStore<T: Encodable>(_ object: T, forKey key: String) {
        if let data = try? Constants.jsonEncoder.encode(object) {
            repository.set(data, forKey: key)
        }
    }

    // MARK: - Tests for Retrieval Functions
    func testPinnedDomainsWithNoData() {
        XCTAssertTrue(BlogListReducer.pinnedDomains(repository: repository).isEmpty)
    }

    func testPinnedDomainsWithValidData() {
        let pinnedDomains = [BlogListReducer.PinnedDomain(domain: "example.com", isRecent: true)]
        encodeAndStore(pinnedDomains, forKey: BlogListReducer.Constants.pinnedDomainsKey)

        let result = BlogListReducer.pinnedDomains(repository: repository)
        XCTAssertEqual(result, pinnedDomains)
    }

    func testRecentDomainsWithNoData() {
        XCTAssertTrue(BlogListReducer.recentDomains(repository: repository).isEmpty)
    }

    func testRecentDomainsWithValidData() {
        let recentDomains = ["example.com"]
        encodeAndStore(recentDomains, forKey: BlogListReducer.Constants.recentDomainsKey)

        let result = BlogListReducer.recentDomains(repository: repository)
        XCTAssertEqual(result, recentDomains)
    }

    func testPinnedSites() {
        let sites: [BlogListView.Site] = [
            .init(
                title: "1",
                domain: "example1.com",
                imageURL: nil
            ),
            .init(
                title: "2",
                domain: "example2.com",
                imageURL: nil
            ),
            .init(
                title: "3",
                domain: "example3.com",
                imageURL: nil
            )
        ]
        let pinnedDomains: [String] = ["example1.com", "wordpress.com"]
        let result = BlogListReducer.pinnedSites(allSites: sites, pinnedDomains: pinnedDomains)

        XCTAssertEqual(
            result,
            [
                BlogListView.Site(
                    title: "1",
                    domain: "example1.com",
                    imageURL: nil
                )
            ]
        )
    }

    func testAllSitesExcludesPinnedAndRecent() {
        let sites: [BlogListView.Site] = [
            .init(
                title: "1",
                domain: "example1.com",
                imageURL: nil
            ),
            .init(
                title: "2",
                domain: "example2.com",
                imageURL: nil
            ),
            .init(
                title: "3",
                domain: "example3.com",
                imageURL: nil
            )
        ]

        let result = BlogListReducer.allSites(
            allSites: sites,
            pinnedDomains: ["example2.com"],
            recentDomains: ["example3.com"]
        )

        XCTAssertEqual(result, [BlogListView.Site(title: "1", domain: "example1.com", imageURL: nil)])
    }

    func testRecentSites() {
        let sites: [BlogListView.Site] = [
            .init(
                title: "1",
                domain: "example1.com",
                imageURL: nil
            ),
            .init(
                title: "2",
                domain: "example2.com",
                imageURL: nil
            ),
            .init(
                title: "3",
                domain: "example3.com",
                imageURL: nil
            )
        ]

        let recentDomains = ["example2.com", "example1.com"]

        let result = BlogListReducer.recentSites(allSites: sites, recentDomains: recentDomains)

        XCTAssertEqual(
            result,
            [
                .init(title: "2", domain: "example2.com", imageURL: nil),
                .init(title: "1", domain: "example1.com", imageURL: nil)
            ]
        )
    }

    // MARK: - Tests for Domain Toggling
    func testToggleDomainPinAdd() {
        let domain = "example.com"
        BlogListReducer.toggleDomainPin(repository: repository, domain: domain)
        let result = BlogListReducer.pinnedDomains(repository: repository)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.domain, domain)
    }

    func testToggleDomainPinRemove() {
        let domain = "example.com"
        encodeAndStore(
            [
                BlogListReducer.PinnedDomain(domain: domain, isRecent: false)
            ],
            forKey: BlogListReducer.Constants.pinnedDomainsKey
        )
        BlogListReducer.toggleDomainPin(repository: repository, domain: domain)
        XCTAssertTrue(BlogListReducer.pinnedDomains(repository: repository).isEmpty)
    }

    // MARK: - Tests for Domain Selection
    func testDidSelectDomainAlreadyPinned() {
        let domain = "example.com"
        encodeAndStore(
            [
                BlogListReducer.PinnedDomain(domain: domain, isRecent: false)
            ],
            forKey: BlogListReducer.Constants.pinnedDomainsKey
        )
        BlogListReducer.didSelectDomain(repository: repository, domain: domain)
        // Ensure no change to recent domains if the domain is already pinned
        XCTAssertTrue(BlogListReducer.recentDomains(repository: repository).isEmpty)
    }

    func testDidSelectDomainAddToRecent() {
        let domain = "example.com"
        BlogListReducer.didSelectDomain(repository: repository, domain: domain)
        let result = BlogListReducer.recentDomains(repository: repository)
        XCTAssertEqual(result, [domain])
    }

    func testDidSelectDomainRespectsRecentsLimit() {
        let domains = (1...10).map { "example\($0).com" }
        domains.forEach { BlogListReducer.didSelectDomain(repository: repository, domain: $0) }
        let result = BlogListReducer.recentDomains(repository: repository)
        XCTAssertEqual(result.count, BlogListReducer.Constants.recentsTotalLimit)
    }


}
