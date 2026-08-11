import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
import WordPressKitModels
@testable import WordPress
@testable import WordPressData

final class BlogServiceUpdateSettingsTests: CoreDataTestCase {

    private var service: BlogService!

    override func setUp() {
        super.setUp()
        service = BlogService(coreDataStack: contextManager)
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    private func makeChanges(name: String) -> BlogSettingsChanges {
        let changes = BlogSettingsChanges()
        changes.name = name
        return changes
    }

    private func attachSettings(to blog: Blog) {
        blog.settings = NSEntityDescription.insertNewObject(
            forEntityName: "BlogSettings", into: mainContext) as? BlogSettings
    }

    // MARK: WP.com

    private func makeDotComBlog(dotComID: Int = 12345) -> Blog {
        let blog = BlogBuilder(mainContext)
            .withAnAccount()
            .with(dotComID: dotComID)
            .build()
        attachSettings(to: blog)
        blog.settings?.name = "Old Title"
        try! mainContext.save()
        return blog
    }

    func testDotComTitleOnlySaveSendsOnlyTitleAndSucceedsOnce() {
        let blog = makeDotComBlog()
        var capturedParams: [String: Any] = [:]
        stub(condition: pathEndsWith("/sites/12345/settings")) { request in
            if let body = request.ohhttpStubs_httpBody,
                let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
            {
                capturedParams = json
            }
            return HTTPStubsResponse(
                jsonObject: ["updated": ["blogname": "New Title"]], statusCode: 200, headers: nil)
        }

        let success = expectation(description: "success called exactly once")
        service.updateSettings(for: blog, changes: makeChanges(name: "New Title"), success: {
            success.fulfill()
        }, failure: { _ in
            XCTFail("failure must not be called")
        })
        wait(for: [success], timeout: 5)

        XCTAssertEqual(capturedParams["blogname"] as? String, "New Title")
        XCTAssertNil(capturedParams["blogdescription"])
        XCTAssertNil(capturedParams["amp_is_enabled"])
    }

    func testDotComServerErrorFailsOnceAndPersistsNothing() {
        let blog = makeDotComBlog()
        stub(condition: pathEndsWith("/sites/12345/settings")) { _ in
            HTTPStubsResponse(jsonObject: ["error": "unauthorized"], statusCode: 403, headers: nil)
        }

        let failure = expectation(description: "failure called exactly once")
        service.updateSettings(for: blog, changes: makeChanges(name: "New Title"), success: {
            XCTFail("success must not be called")
        }, failure: { _ in
            failure.fulfill()
        })
        wait(for: [failure], timeout: 5)

        // Nothing was persisted by the write path: the committed value is unchanged.
        mainContext.refreshAllObjects()
        XCTAssertEqual(blog.settings?.name, "Old Title")
    }

    func testFailedSaveDoesNotBlockNextSave() {
        let blog = makeDotComBlog()
        var requestCount = 0
        stub(condition: pathEndsWith("/sites/12345/settings")) { _ in
            requestCount += 1
            if requestCount == 1 {
                return HTTPStubsResponse(
                    jsonObject: ["error": "unauthorized"],
                    statusCode: 403,
                    headers: nil
                )
            }
            return HTTPStubsResponse(
                jsonObject: ["updated": ["blogname": "Second Title"]],
                statusCode: 200,
                headers: nil
            )
        }

        let firstFailure = expectation(description: "first save fails")
        let secondSuccess = expectation(description: "second save succeeds")
        service.updateSettings(
            for: blog,
            changes: makeChanges(name: "First Title"),
            success: {
                XCTFail("first save must not succeed")
            },
            failure: { _ in
                firstFailure.fulfill()
            }
        )
        service.updateSettings(
            for: blog,
            changes: makeChanges(name: "Second Title"),
            success: {
                secondSuccess.fulfill()
            },
            failure: { _ in
                XCTFail("second save must not fail")
            }
        )
        wait(for: [firstFailure, secondSuccess], timeout: 10)

        XCTAssertEqual(requestCount, 2)
    }

    // MARK: XML-RPC

    private func makeSelfHostedBlog() -> Blog {
        let blog = BlogBuilder(mainContext)
            .with(username: "admin")
            .build()
        blog.xmlrpc = "https://selfhosted.example/xmlrpc.php"
        blog.password = "secret"
        attachSettings(to: blog)
        try! mainContext.save()
        return blog
    }

    // The XML-RPC transport can only write the title/tagline subset. Its wire
    // payload is `RemoteBlogOptionsHelper.remoteOptionsForUpdatingBlogTitleAndTagline`
    // applied to the sparse settings the write path maps from `changes` (see
    // `performSettingsUpdate`'s `.xmlrpc` branch). This asserts that subset
    // directly: OHHTTPStubs does not intercept `WordPressOrgXMLRPCApi`'s
    // URLSession in this test target, so an end-to-end XML-RPC round trip is
    // verified in `WordPressKitTests` instead. The one-callback contract for
    // the XML-RPC branch is covered by `testXMLRPCUnsupportedFieldsSkipRequestAndSucceed`.
    func testXMLRPCTaglineOnlyMapsToTaglineOptionOnly() {
        let changes = BlogSettingsChanges()
        changes.tagline = "New tagline"
        let options = RemoteBlogOptionsHelper.remoteOptionsForUpdatingBlogTitleAndTagline(
            changes.toRemoteBlogSettings())
        XCTAssertEqual(options["blog_tagline"] as? String, "New tagline")
        XCTAssertNil(options["blog_title"])
    }

    func testXMLRPCUnsupportedFieldsSkipRequestAndSucceed() {
        let blog = makeSelfHostedBlog()
        var requestCount = 0
        stub(condition: isHost("selfhosted.example")) { _ in
            requestCount += 1
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        let changes = BlogSettingsChanges()
        changes.dateFormat = "F j, Y"  // XML-RPC cannot write this
        let success = expectation(description: "success without request")
        service.updateSettings(for: blog, changes: changes, success: { success.fulfill() },
                               failure: { _ in XCTFail("unexpected failure") })
        wait(for: [success], timeout: 5)
        XCTAssertEqual(requestCount, 0)
    }

    // MARK: Empty changes / no transport

    func testEmptyChangesSucceedWithoutRequest() {
        let blog = makeSelfHostedBlog()
        var requestCount = 0
        stub(condition: { _ in true }) { _ in
            requestCount += 1
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }
        let success = expectation(description: "success")
        service.updateSettings(for: blog, changes: BlogSettingsChanges(), success: { success.fulfill() },
                               failure: { _ in XCTFail("unexpected failure") })
        wait(for: [success], timeout: 5)
        XCTAssertEqual(requestCount, 0)
    }

    func testNoTransportFailsWithNoAvailableTransport() {
        // No account (so not WP.com), no application password (so not Core
        // REST), and no XML-RPC endpoint: every transport is unavailable.
        let blog = BlogBuilder(mainContext, dotComID: nil).with(username: "admin").build()
        try! mainContext.save()

        let failure = expectation(description: "failure")
        service.updateSettings(for: blog, changes: makeChanges(name: "T"), success: {
            XCTFail("success must not be called")
        }, failure: { error in
            XCTAssertTrue(error is BlogSettingsServiceError)
            failure.fulfill()
        })
        wait(for: [failure], timeout: 5)
    }

    // MARK: Persistence

    // On success, exactly the acknowledged changes are persisted; undeclared
    // fields are untouched. Driven over WP.com because its transport is the
    // one OHHTTPStubs reliably intercepts in this target; persistence itself
    // is transport-agnostic (`persist(_:for:)` runs after any successful save).
    func testSuccessPersistsOnlyDeclaredFields() {
        let blog = makeDotComBlog()
        blog.settings?.name = "Old Title"
        blog.settings?.tagline = "Old tagline"
        try! mainContext.save()
        stub(condition: pathEndsWith("/sites/12345/settings")) { _ in
            HTTPStubsResponse(jsonObject: ["updated": ["blogname": "New Title"]], statusCode: 200, headers: nil)
        }

        let success = expectation(description: "success")
        service.updateSettings(for: blog, changes: makeChanges(name: "New Title"),
                               success: { success.fulfill() },
                               failure: { _ in XCTFail("unexpected failure") })
        wait(for: [success], timeout: 5)

        mainContext.refreshAllObjects()
        XCTAssertEqual(blog.settings?.name, "New Title")
        XCTAssertEqual(blog.settings?.tagline, "Old tagline")
    }

    // MARK: Serialization

    func testOverlappingSavesFromTwoServiceInstancesAreSequential() {
        let blog = makeDotComBlog()
        var responseTimes: [Date] = []
        var requestTimes: [Date] = []
        stub(condition: pathEndsWith("/sites/12345/settings")) { _ in
            requestTimes.append(Date())
            let response = HTTPStubsResponse(
                jsonObject: ["updated": [:]], statusCode: 200, headers: nil)
            response.responseTime = 0.5
            responseTimes.append(Date().addingTimeInterval(0.5))
            return response
        }

        let first = expectation(description: "first completes")
        let second = expectation(description: "second completes")
        let serviceA = BlogService(coreDataStack: contextManager)
        let serviceB = BlogService(coreDataStack: contextManager)
        serviceA.updateSettings(for: blog, changes: makeChanges(name: "A"),
                                success: { first.fulfill() }, failure: { _ in XCTFail() })
        serviceB.updateSettings(for: blog, changes: makeChanges(name: "B"),
                                success: { second.fulfill() }, failure: { _ in XCTFail() })
        wait(for: [first, second], timeout: 10)

        XCTAssertEqual(requestTimes.count, 2)
        // The second request must not start before the first response finished.
        XCTAssertGreaterThanOrEqual(requestTimes[1], responseTimes[0])
    }

    func testOverlappingSavesForDifferentBlogsAreSequential() {
        let firstBlog = makeDotComBlog(dotComID: 12345)
        let secondBlog = makeDotComBlog(dotComID: 67890)
        var responseTimes: [Date] = []
        var requestTimes: [Date] = []
        stub(condition: pathEndsWith("/settings")) { _ in
            requestTimes.append(Date())
            let response = HTTPStubsResponse(
                jsonObject: ["updated": [:]],
                statusCode: 200,
                headers: nil
            )
            response.responseTime = 0.5
            responseTimes.append(Date().addingTimeInterval(0.5))
            return response
        }

        let first = expectation(description: "first completes")
        let second = expectation(description: "second completes")
        let serviceA = BlogService(coreDataStack: contextManager)
        let serviceB = BlogService(coreDataStack: contextManager)
        serviceA.updateSettings(
            for: firstBlog,
            changes: makeChanges(name: "A"),
            success: { first.fulfill() },
            failure: { _ in XCTFail() }
        )
        serviceB.updateSettings(
            for: secondBlog,
            changes: makeChanges(name: "B"),
            success: { second.fulfill() },
            failure: { _ in XCTFail() }
        )
        wait(for: [first, second], timeout: 10)

        XCTAssertEqual(requestTimes.count, 2)
        XCTAssertGreaterThanOrEqual(requestTimes[1], responseTimes[0])
    }

    // An application-password blog must resolve to the Core REST transport.
    // Asserted at the source-resolution seam (the plan's documented fallback):
    // the full-path Core REST wire behavior is covered by
    // `BlogServiceRemoteCoreRESTUpdateTests`, and driving the request here
    // would depend on the `WordPressClientFactory` session being stub-backed.
    @MainActor
    func testApplicationPasswordBlogUsesCoreRESTSource() throws {
        let keychain = TestKeychain()
        // Set the URL before storing the app password: the token is keyed by
        // the blog's URL string, so it must match what resolution reads back.
        let blog = BlogBuilder(mainContext, dotComID: nil)
            .with(username: "admin")
            .with(url: "https://selfhosted.example")
            .with(restApiRootURL: "https://selfhosted.example/wp-json/")
            .withApplicationPassword("app-password", using: keychain)
            .build()
        try mainContext.save()

        // Building the Core REST remote constructs a factory-backed
        // WordPressClient whose eager caches fire background requests. Stub the
        // host so this unit test stays offline and quiet; the assertion below
        // only cares about which transport resolution selects.
        stub(condition: isHost("selfhosted.example")) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        let source = try service.settingsSource(for: TaggedManagedObjectID(blog), keychain: keychain)
        guard case .coreREST = source else {
            return XCTFail("expected Core REST source, got \(source)")
        }
    }
}
