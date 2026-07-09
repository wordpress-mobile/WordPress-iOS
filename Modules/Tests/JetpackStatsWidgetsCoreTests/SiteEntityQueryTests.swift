import Foundation
import Testing
@testable import JetpackStatsWidgetsCore

@Suite
struct SiteEntityQueryTests {

    /// Uses the `xctest` app-group prefix so `HomeWidgetCache` writes to a temporary
    /// directory instead of a real security application group.
    private let appGroup =
        "\(HomeWidgetCache<HomeWidgetTodayData>.testAppGroupNamePrefix).site-entity-query.\(UUID().uuidString)"

    private var cache: HomeWidgetCache<HomeWidgetTodayData> {
        HomeWidgetCache<HomeWidgetTodayData>(appGroup: appGroup)
    }

    private var query: SiteEntityQuery {
        SiteEntityQuery(appGroup: appGroup)
    }

    private func populateCache(_ sites: [HomeWidgetTodayData]) throws {
        try cache.write(items: Dictionary(uniqueKeysWithValues: sites.map { ($0.siteID, $0) }))
    }

    private func makeSite(siteID: Int, name: String, url: String = "https://example.com") -> HomeWidgetTodayData {
        HomeWidgetTodayData(
            siteID: siteID,
            siteName: name,
            url: url,
            timeZone: .current,
            date: Date(),
            stats: TodayWidgetStats(views: 0, visitors: 0, likes: 0, comments: 0)
        )
    }

    // MARK: - Entity mapping

    @Test
    func entityFieldsMapFromWidgetData() async throws {
        try populateCache([
            makeSite(siteID: 1234567, name: "My Test Site", url: "https://mytestsite.wordpress.com/some/path")
        ])

        let entities = try await query.entities(for: ["1234567"])

        let entity = try #require(entities.first)
        #expect(entity.id == "1234567")
        #expect(entity.name == "My Test Site")
        #expect(entity.domain == "mytestsite.wordpress.com")
    }

    @Test
    func entityDomainIsNilForUnparseableURL() async throws {
        try populateCache([makeSite(siteID: 1, name: "Broken", url: "")])

        let entities = try await query.entities(for: ["1"])

        let entity = try #require(entities.first)
        #expect(entity.domain == nil)
    }

    // MARK: - entities(for:)

    @Test
    func entitiesForIdentifiersResolvesCachedSites() async throws {
        try populateCache([
            makeSite(siteID: 1, name: "Alpha"),
            makeSite(siteID: 2, name: "Beta"),
            makeSite(siteID: 3, name: "Gamma")
        ])

        let entities = try await query.entities(for: ["1", "3"])

        #expect(entities.map(\.id) == ["1", "3"])
        #expect(entities.map(\.name) == ["Alpha", "Gamma"])
    }

    /// A configured site must never silently resolve to nothing (the widget would
    /// fall back to the default site): identifiers missing from the cache are
    /// preserved as placeholder entities.
    @Test
    func entitiesForIdentifiersPreservesUnknownIdentifiers() async throws {
        try populateCache([makeSite(siteID: 1, name: "Alpha")])

        let entities = try await query.entities(for: ["1", "999"])

        #expect(entities.map(\.id) == ["1", "999"])
        #expect(entities.first?.name == "Alpha")
        #expect(entities.last?.name == "999")
    }

    @Test
    func entitiesForIdentifiersPreservesIdentifiersWhenCacheIsMissing() async throws {
        let entities = try await query.entities(for: ["1"])

        #expect(entities.map(\.id) == ["1"])
    }

    // MARK: - suggestedEntities()

    @Test
    func suggestedEntitiesReturnsAllCachedSitesSortedByName() async throws {
        try populateCache([
            makeSite(siteID: 3, name: "zebra"),
            makeSite(siteID: 1, name: "Apple"),
            makeSite(siteID: 2, name: "mango")
        ])

        let entities = try await query.suggestedEntities()

        #expect(entities.map(\.name) == ["Apple", "mango", "zebra"])
    }

    @Test
    func suggestedEntitiesBreaksNameTiesByDomain() async throws {
        try populateCache([
            makeSite(siteID: 1, name: "Same Name", url: "https://zzz.example.com"),
            makeSite(siteID: 2, name: "Same Name", url: "https://aaa.example.com")
        ])

        let entities = try await query.suggestedEntities()

        #expect(entities.map(\.id) == ["2", "1"])
    }

    @Test
    func suggestedEntitiesIsEmptyWhenCacheIsMissing() async throws {
        let entities = try await query.suggestedEntities()

        #expect(entities.isEmpty)
    }
}
