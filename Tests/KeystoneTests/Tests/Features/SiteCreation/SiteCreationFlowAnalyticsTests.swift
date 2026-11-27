import Testing

@testable import WordPress

// Main actor isolation keeps these synchronous tests from interleaving with other suites that share
// `TestAnalyticsTracker`, such as `MediaTrackerAdapterUploadEventsTests`.
@Suite(.serialized)
@MainActor
struct SiteCreationFlowAnalyticsTests {
    @Test(arguments: [(SiteCreationFlow.short, "mobile-blank"), (.current, "mobile")])
    func accessedEventCarriesFlow(flow: SiteCreationFlow, expectedName: String) throws {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        SiteCreationAnalyticsHelper.trackSiteCreationAccessed(source: "my_site_no_sites", flow: flow)

        let event = try #require(TestAnalyticsTracker.tracked.last)
        #expect(event.stat == .enhancedSiteCreationAccessed)
        #expect(event.value(for: "site_creation_flow") == expectedName)
        #expect(event.value(for: "source") == "my_site_no_sites")
    }

    @Test(arguments: [(SiteCreationFlow.short, "mobile-blank"), (.current, "mobile")])
    func siteCreatedEventCarriesFlow(flow: SiteCreationFlow, expectedName: String) throws {
        TestAnalyticsTracker.setup()
        defer { TestAnalyticsTracker.tearDown() }

        SiteCreationAnalyticsHelper.trackSiteCreationSuccess(nil, flow: flow)

        let event = try #require(TestAnalyticsTracker.tracked.last)
        #expect(event.stat == .createdSite)
        #expect(event.value(for: "site_creation_flow") == expectedName)
    }
}
