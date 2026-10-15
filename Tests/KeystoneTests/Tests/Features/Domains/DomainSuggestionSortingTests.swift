import Foundation
import Testing
import WordPressKit

@testable import WordPress

struct DomainSuggestionSortingTests {
    @Test func partitionTakesFreeEntryFromLiveResponse() throws {
        let suggestions = try loadLiveSuggestions()
        #expect(suggestions.first?.isFree == true)

        let (free, rows) = DomainSuggestionSorting.partitioned(suggestions)

        #expect(free?.domainName == "bluebirdbakery3.wordpress.com")
        #expect(rows.count == suggestions.count - 1)
        #expect(rows.allSatisfy { !$0.isFree })
        #expect(rows.map(\.domainName) == suggestions.dropFirst().map(\.domainName))
    }

    @Test func partitionSelectsFreeEntryByFlagNotPosition() throws {
        var suggestions = try loadLiveSuggestions()
        let free = suggestions.removeFirst()
        suggestions.insert(free, at: 5)

        let result = DomainSuggestionSorting.partitioned(suggestions)

        #expect(result.free?.domainName == free.domainName)
        #expect(!result.rows.contains { $0.domainName == free.domainName })
        #expect(result.rows.count == suggestions.count - 1)
    }

    @Test func partitionWithoutFreeEntryHasNoCard() throws {
        let suggestions = try loadLiveSuggestions().filter { !$0.isFree }

        let (free, rows) = DomainSuggestionSorting.partitioned(suggestions)

        #expect(free == nil)
        #expect(rows.map(\.domainName) == suggestions.map(\.domainName))
    }

    @Test func partitionKeepsAdditionalFreeEntriesInRows() {
        let suggestions = [
            makeSuggestion("first.wordpress.com", isFree: true),
            makeSuggestion("second.wordpress.com", isFree: true),
            makeSuggestion("third.wordpress.com", isFree: true)
        ]

        let (free, rows) = DomainSuggestionSorting.partitioned(suggestions)

        #expect(free?.domainName == "first.wordpress.com")
        #expect(rows.map(\.domainName) == ["second.wordpress.com", "third.wordpress.com"])
    }

    @Test func sortingPutsTwoPaidDomainsFirstThenTheRest() {
        let suggestions = [
            makeSuggestion("free.wordpress.com", isFree: true),
            makeSuggestion("one.com"),
            makeSuggestion("other.wordpress.com", isFree: true),
            makeSuggestion("two.com"),
            makeSuggestion("three.com")
        ]

        let sorted = DomainSuggestionSorting.sorted(suggestions)

        #expect(
            sorted.map(\.domainName) == [
                "one.com",
                "two.com",
                "free.wordpress.com",
                "other.wordpress.com",
                "three.com"
            ]
        )
    }

    @Test func emptyInputYieldsNothing() {
        let (free, rows) = DomainSuggestionSorting.partitioned([])

        #expect(free == nil)
        #expect(rows.isEmpty)
    }

    // MARK: - Helpers

    /// A `domains/suggestions` response captured on 2026-10-15 with the Jetpack site creation parameters
    /// (`include_wordpressdotcom=true`, `include_dotblogsubdomain=false`, `vendor=mobile`).
    private func loadLiveSuggestions() throws -> [DomainSuggestion] {
        let data = try Bundle.test.json(named: "domain-suggestions-free-and-paid")
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [[String: AnyObject]])
        return try json.map(DomainSuggestion.init(json:))
    }

    private func makeSuggestion(_ domainName: String, isFree: Bool = false) -> DomainSuggestion {
        DomainSuggestion(domainName: domainName, productID: nil, supportsPrivacy: nil, costString: "", isFree: isFree)
    }
}
