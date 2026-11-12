import Foundation
import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
@testable import WordPress
@testable import WordPressData

// XCTest rather than Swift Testing: these tests register global HTTP stubs and read the shared test analytics tracker,
// and `HTTPStubs.removeAllStubs()` in a parallel Swift Testing case would remove another case's stubs.
@MainActor
final class StarterDesignApplierTests: CoreDataTestCase {
    private let siteID = 4242
    private var record: BlankSiteRecord!
    private var requestedPaths: [String] = []
    private var activatedTheme: String?

    private var activationPath: String { "/rest/v1.1/sites/\(siteID)/themes/mine" }
    private var themeSetupPath: String { "/wpcom/v2/sites/\(siteID)/theme-setup" }

    override func setUp() {
        super.setUp()
        record = BlankSiteRecord(repository: InMemoryUserDefaults())
        record.insert(siteID: siteID)
        requestedPaths = []
        activatedTheme = nil
        TestAnalyticsTracker.setup()
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        TestAnalyticsTracker.tearDown()
        record = nil
        super.tearDown()
    }

    func testActivationFailureThrowsAndLeavesTheCard() async {
        stubRequest(path: activationPath, status: 500, body: #"{"error": "unknown", "message": "Went wrong"}"#)
        stubRequest(path: themeSetupPath, body: #"{"result": "success"}"#)

        do {
            try await makeApplier(blog: makeSimpleSite()).apply(makeDesign())
            XCTFail("Expected the activation error")
        } catch {}

        XCTAssertTrue(record.contains(siteID: siteID))
        XCTAssertFalse(trackedAppliedEvent)
        XCTAssertEqual(requestedPaths, [activationPath])
    }

    func testActivationSuccessAppliesAndRunsThemeSetup() async throws {
        stubRequest(path: activationPath, body: Self.activatedThemeBody)
        stubRequest(path: themeSetupPath, body: #"{"result": "success"}"#)

        let themeSetup = try await makeApplier(blog: makeSimpleSite()).apply(makeDesign())
        await themeSetup?.value

        XCTAssertEqual(activatedTheme, "ury")
        XCTAssertFalse(record.contains(siteID: siteID))
        XCTAssertTrue(trackedAppliedEvent)
        XCTAssertEqual(requestedPaths, [activationPath, themeSetupPath])
    }

    func testThemeSetupFailureStillApplies() async throws {
        stubRequest(path: activationPath, body: Self.activatedThemeBody)
        stubRequest(path: themeSetupPath, status: 403, body: #"{"error": "rest_forbidden", "message": "Nope"}"#)

        let themeSetup = try await makeApplier(blog: makeSimpleSite()).apply(makeDesign())
        await themeSetup?.value

        XCTAssertFalse(record.contains(siteID: siteID))
        XCTAssertTrue(trackedAppliedEvent)
    }

    func testAtomicSiteSkipsThemeSetup() async throws {
        stubRequest(path: activationPath, body: Self.activatedThemeBody)
        stubRequest(path: themeSetupPath, body: #"{"result": "success"}"#)
        let blog = BlogBuilder(mainContext, dotComID: NSNumber(value: siteID))
            .with(isHostedAtWPCom: false)
            .with(atomic: true)
            .build()

        let themeSetup = try await makeApplier(blog: blog).apply(makeDesign())

        XCTAssertNil(themeSetup)
        XCTAssertEqual(requestedPaths, [activationPath])
        XCTAssertFalse(record.contains(siteID: siteID))
    }

    // MARK: - Helpers

    private static let activatedThemeBody = #"{"id": "ury", "name": "Ury", "stylesheet": "pub/ury", "active": true}"#

    private var trackedAppliedEvent: Bool {
        TestAnalyticsTracker.tracked.contains {
            $0.event == "design_card_design_applied" && $0.value(for: "design") == "ury"
        }
    }

    private func makeApplier(blog: Blog) -> StarterDesignApplier {
        StarterDesignApplier(
            blog: blog,
            api: WordPressComRestApi(oAuthToken: "token", userAgent: nil),
            record: record
        )
    }

    private func makeSimpleSite() -> Blog {
        BlogBuilder(mainContext, dotComID: NSNumber(value: siteID))
            .isHostedAtWPcom()
            .with(atomic: false)
            .build()
    }

    private func makeDesign() -> RemoteSiteDesign {
        StarterDesignSectionLoader.siteDesign(
            from: StarterDesign(
                slug: "ury",
                title: "Ury",
                stylesheet: "pub/ury",
                categories: [],
                themeTier: "free",
                screenshot: nil
            ),
            siteTitle: nil,
            language: "en"
        )
    }

    /// Records the request path and, for a theme activation, the theme sent in the body.
    private func stubRequest(path: String, status: Int32 = 200, body: String) {
        stub(condition: isPath(path)) { [weak self] request in
            self?.requestedPaths.append(path)
            let json = request.ohhttpStubs_httpBody.flatMap {
                try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
            }
            if let theme = json?["theme"] as? String {
                self?.activatedTheme = theme
            }
            return HTTPStubsResponse(
                data: Data(body.utf8),
                statusCode: status,
                headers: ["Content-Type": "application/json"]
            )
        }
    }
}
