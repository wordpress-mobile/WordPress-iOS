import XCTest
@testable import WordPressKit

// XCTest rather than Swift Testing: these tests register global HTTP stubs, which `RemoteTestCase` removes between
// tests. Parallel Swift Testing cases would remove each other's stubs.
final class StarterDesignServiceRemoteTests: RemoteTestCase, RESTTestable {
    private let catalogEndpoint = "wpcom/v2/starter-designs"
    private let themeSetupEndpoint = "wpcom/v2/sites/123/theme-setup"

    private var remote: StarterDesignServiceRemote!

    override func setUp() {
        super.setUp()
        remote = StarterDesignServiceRemote(wordPressComRestApi: getRestApi())
    }

    override func tearDown() {
        remote = nil
        super.tearDown()
    }

    // MARK: - Catalog

    func testFetchStarterDesignsDecodesLiveResponse() async throws {
        stubRemoteResponse(catalogEndpoint, filename: "starter-designs-success.json", contentType: .ApplicationJSON)

        let designs = try await remote.fetchStarterDesigns()

        XCTAssertEqual(designs.map(\.slug), ["formwork", "ury", "golazo", "primarium", "archivist", "creatio-2"])

        let ury = try XCTUnwrap(designs.first { $0.slug == "ury" })
        XCTAssertEqual(ury.title, "Ury")
        XCTAssertEqual(ury.stylesheet, "pub/ury")
        XCTAssertEqual(ury.themeID, "ury")
        XCTAssertEqual(ury.themeTier, "free")
        XCTAssertEqual(ury.categories.map(\.slug), ["blog", "art-design"])
        XCTAssertEqual(ury.categories.first?.name, "Blog")
        XCTAssertEqual(ury.screenshot?.contains("/themes/pub/ury/screenshot.png"), true)
        XCTAssertFalse(ury.isVirtual)

        XCTAssertEqual(designs.first { $0.slug == "formwork" }?.themeTier, "premium")
        XCTAssertEqual(designs.first { $0.slug == "creatio-2" }?.isVirtual, true)
    }

    func testFetchStarterDesignsDropsDesignsThatFailToDecode() async throws {
        let body = """
            {"static": {"designs": [
                {"slug": "ury", "title": "Ury", "recipe": {"stylesheet": "pub/ury"}, "categories": [], "theme_tier": {"slug": "free"}},
                {"slug": "broken", "title": "Broken"}
            ]}}
            """
        stubRemoteResponse(catalogEndpoint, data: Data(body.utf8), contentType: .ApplicationJSON)

        let designs = try await remote.fetchStarterDesigns()

        XCTAssertEqual(designs.map(\.slug), ["ury"])
    }

    func testFetchStarterDesignsFailsOnServerError() async {
        stubRemoteResponse(catalogEndpoint, data: Data("{}".utf8), contentType: .ApplicationJSON, status: 500)

        do {
            _ = try await remote.fetchStarterDesigns()
            XCTFail("Expected an error")
        } catch {}
    }

    // MARK: - Theme setup

    func testThemeSetupWithSuccessResultIsCompleted() async throws {
        let body = #"{"blog": "example.wordpress.com", "result": "success"}"#
        stubRemoteResponse(themeSetupEndpoint, data: Data(body.utf8), contentType: .ApplicationJSON)

        let isCompleted = try await remote.runThemeSetup(siteID: 123)

        XCTAssertTrue(isCompleted)
    }

    func testThemeSetupWithFalseBodyIsNotCompletedAndNotAnError() async throws {
        stubRemoteResponse(themeSetupEndpoint, data: Data("false".utf8), contentType: .ApplicationJSON)

        let isCompleted = try await remote.runThemeSetup(siteID: 123)

        XCTAssertFalse(isCompleted)
    }

    func testThemeSetupWithOtherResultIsNotCompleted() async throws {
        stubRemoteResponse(
            themeSetupEndpoint,
            data: Data(#"{"result": "skipped"}"#.utf8),
            contentType: .ApplicationJSON
        )

        let isCompleted = try await remote.runThemeSetup(siteID: 123)

        XCTAssertFalse(isCompleted)
    }

    func testThemeSetupWithMalformedBodyThrows() async {
        stubRemoteResponse(themeSetupEndpoint, data: Data("\"nope\"".utf8), contentType: .ApplicationJSON)

        do {
            _ = try await remote.runThemeSetup(siteID: 123)
            XCTFail("Expected an error")
        } catch {}
    }
}
