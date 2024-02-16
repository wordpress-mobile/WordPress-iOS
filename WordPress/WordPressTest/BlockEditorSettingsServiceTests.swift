import XCTest
import Nimble
import OHHTTPStubs
@testable import WordPress

class BlockEditorSettingsServiceTests: CoreDataTestCase {
    let expectationTimeout = TimeInterval(1)
    private let twentytwentyResponseFilename = "get_wp_v2_themes_twentytwenty"
    private let twentytwentyoneResponseFilename = "get_wp_v2_themes_twentytwentyone"
    private let blockSettingsNOTThemeJSONResponseFilename = "wp-block-editor-v1-settings-success-NotThemeJSON"
    private let blockSettingsThemeJSONResponseFilename = "wp-block-editor-v1-settings-success-ThemeJSON"

    private var service: BlockEditorSettingsService!
    var gssOriginalValue: Bool!
    private var blog: Blog!

    override func setUp() {
        blog = BlogBuilder(mainContext)
            .with(wordPressVersion: "5.8")
            .withAnAccount()
            .build()
        contextManager.saveContextAndWait(mainContext)
        service = BlockEditorSettingsService(blog: blog, coreDataStack: contextManager)
    }

    // MARK: Editor `theme_supports` support
    func testThemeSupportsNewTheme() {
        blog = BlogBuilder(mainContext)
            .with(wordPressVersion: "5.7")
            .with(isHostedAtWPCom: true)
            .withAnAccount()
            .build()
        contextManager.saveContextAndWait(mainContext)

        let mockedResponse = mockedData(withFilename: twentytwentyoneResponseFilename)
        stubThemeRequest(response: HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil))

        service = BlockEditorSettingsService(blog: blog, coreDataStack: contextManager)
        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchSettings { result in
            switch result {
            case .success(let settings):
                XCTAssertTrue(settings.hasChanges)
                XCTAssertNotNil(settings.blockEditorSettings)
            case .failure:
                XCTFail()
            }
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: expectationTimeout)
        validateThemeResponse()
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
    }

    func testThemeSupportsThemeChange() {
        blog = BlogBuilder(mainContext)
            .with(wordPressVersion: "5.7")
            .with(isHostedAtWPCom: true)
            .withAnAccount()
            .build()
        contextManager.saveContextAndWait(mainContext)

        service = BlockEditorSettingsService(blog: blog, coreDataStack: contextManager)

        setData(withFilename: twentytwentyResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        let mockedResponse = mockedData(withFilename: twentytwentyoneResponseFilename)
        stubThemeRequest(response: HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil))

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchSettings { result in
            switch result {
            case .success(let settings):
                XCTAssertTrue(settings.hasChanges)
                XCTAssertNotNil(settings.blockEditorSettings)
            case .failure:
                XCTFail()
            }
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: expectationTimeout)
        validateThemeResponse()
        XCTAssertNotEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    func testThemeSupportsThemeIsTheSame() {
        blog = BlogBuilder(mainContext)
            .with(wordPressVersion: "5.7")
            .with(isHostedAtWPCom: true)
            .withAnAccount()
            .build()
        contextManager.saveContextAndWait(mainContext)

        service = BlockEditorSettingsService(blog: blog, coreDataStack: contextManager)

        setData(withFilename: twentytwentyoneResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        let mockedResponse = mockedData(withFilename: twentytwentyoneResponseFilename)
        stubThemeRequest(response: HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil))

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchSettings { result in
            switch result {
            case .success(let settings):
                XCTAssertFalse(settings.hasChanges)
                XCTAssertNotNil(settings.blockEditorSettings)
            case .failure:
                XCTFail()
            }
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: expectationTimeout)
        validateThemeResponse()
        XCTAssertEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    private func validateThemeResponse() {
        XCTAssertGreaterThan(self.blog.blockEditorSettings!.colors!.count, 0)
        XCTAssertGreaterThan(self.blog.blockEditorSettings!.gradients!.count, 0)
    }

    private func stubThemeRequest(response: HTTPStubsResponse) {
        let siteID = blog.dotComID ?? 0
        stub(
            condition:
                isMethodGET()
                    && { $0.url?.absoluteString.contains("/wp/v2/sites/\(siteID)/themes") == true }
                    && { $0.url?.absoluteString.contains("status=active") == true },
            response: { _ in response }
        )
    }

    // MARK: Editor Global Styles support
    func testFetchBlockEditorSettingsNotThemeJSON() {
        let mockedResponse = mockedData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        stubBlockEditorSettingsRequest(response: HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil))

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchSettings { result in
            switch result {
            case .success(let settings):
                XCTAssertTrue(settings.hasChanges)
                XCTAssertNotNil(settings.blockEditorSettings)
            case .failure:
                XCTFail()
            }
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: expectationTimeout)
        validateBlockEditorSettingsResponse(isGlobalStyles: false)
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
    }

    func testFetchBlockEditorSettingsThemeJSON() {
        let mockedResponse = mockedData(withFilename: blockSettingsThemeJSONResponseFilename)
        stubBlockEditorSettingsRequest(response: HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil))

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchSettings { result in
            switch result {
            case .success(let settings):
                XCTAssertTrue(settings.hasChanges)
                XCTAssertNotNil(settings.blockEditorSettings)
            case .failure:
                XCTFail()
            }
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: expectationTimeout)
        validateBlockEditorSettingsResponse()
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
    }

    func testFetchBlockEditorSettingsThemeJSONChangeFromOldEndpointToNew() {
        setData(withFilename: twentytwentyoneResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        let mockedResponse = mockedData(withFilename: blockSettingsThemeJSONResponseFilename)
        stubBlockEditorSettingsRequest(response: HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil))

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchSettings { result in
            switch result {
            case .success(let settings):
                XCTAssertTrue(settings.hasChanges)
                XCTAssertNotNil(settings.blockEditorSettings)
            case .failure:
                XCTFail()
            }
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: expectationTimeout)
        validateBlockEditorSettingsResponse()
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
        XCTAssertNotEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    func testFetchBlockEditorSettingsThemeJSONChangeSettings() {
        setData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        let mockedResponse = mockedData(withFilename: blockSettingsThemeJSONResponseFilename)
        stubBlockEditorSettingsRequest(response: HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil))

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchSettings { result in
            switch result {
            case .success(let settings):
                XCTAssertTrue(settings.hasChanges)
                XCTAssertNotNil(settings.blockEditorSettings)
            case .failure:
                XCTFail()
            }
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: expectationTimeout)
        validateBlockEditorSettingsResponse()
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
        XCTAssertNotEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    func testFetchBlockEditorSettingsNoChange() {

        setData(withFilename: blockSettingsThemeJSONResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        let mockedResponse = mockedData(withFilename: blockSettingsThemeJSONResponseFilename)
        stubBlockEditorSettingsRequest(response: HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil))

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchSettings { result in
            switch result {
            case .success(let settings):
                XCTAssertFalse(settings.hasChanges)
                XCTAssertNotNil(settings.blockEditorSettings)
            case .failure:
                XCTFail()
            }
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: expectationTimeout)
        validateBlockEditorSettingsResponse()
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
        XCTAssertEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    func testFetchBlockEditorSettings_OrgSite_NoPlugin() {
        let first = expectation(description: "The app will call the none-experimental path first but fail because of compatibility reasons")
        let second = expectation(description: "The app will then retry the wp/v2/themes path")

        let mockedResponse = mockedData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        stub(condition: isAbsoluteURLString("https://w.org/wp-json/wp-block-editor/v1/settings?context=mobile")) { _ in
            first.fulfill()
            return HTTPStubsResponse(error: URLError(.networkConnectionLost))
        }
        stub(condition: isAbsoluteURLString("https://w.org/wp-json/wp/v2/themes?status=active")) { _ in
            second.fulfill()
            return HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil)
        }

        let remoteAPI = WordPressOrgRestApi(selfHostedSiteWPJSONURL: URL(string: "https://w.org/wp-json")!, credential: .init(loginURL: URL(string: "https://not-used.org")!, username: "user", password: "pass", adminURL: URL(string: "https://not-used.org")!))
        service = BlockEditorSettingsService(blog: blog, remoteAPI: remoteAPI, coreDataStack: contextManager)

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchSettings { _ in
            waitExpectation.fulfill()
        }

        wait(for: [first, second, waitExpectation], timeout: 0.3, enforceOrder: true)
    }

    func testFetchBlockEditorSettings_OrgSite() {
        let mockedResponse = mockedData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        stub(condition: isAbsoluteURLString("https://w.org/wp-json/wp-block-editor/v1/settings?context=mobile")) { _ in
            HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil)
        }

        let remoteAPI = WordPressOrgRestApi(selfHostedSiteWPJSONURL: URL(string: "https://w.org/wp-json")!, credential: .init(loginURL: URL(string: "https://not-used.org")!, username: "user", password: "pass", adminURL: URL(string: "https://not-used.org")!))
        service = BlockEditorSettingsService(blog: blog, remoteAPI: remoteAPI, coreDataStack: contextManager)

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchSettings { _ in
            waitExpectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeout)
    }

    func testFetchBlockEditorSettings_Com5_8Site() {
        blog = BlogBuilder(mainContext)
            .with(wordPressVersion: "5.8")
            .withAnAccount()
            .build()
        contextManager.saveContextAndWait(mainContext)

        service = BlockEditorSettingsService(blog: blog, coreDataStack: contextManager)

        let mockedResponse = mockedData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        stubBlockEditorSettingsRequest(response: HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil))

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchSettings { _ in
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: expectationTimeout)
    }

    func testFetchBlockEditorSettings_Com5_9Site() {
        blog = BlogBuilder(mainContext)
            .with(wordPressVersion: "5.9")
            .withAnAccount()
            .build()
        contextManager.saveContextAndWait(mainContext)

        service = BlockEditorSettingsService(blog: blog, coreDataStack: contextManager)

        let mockedResponse = mockedData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        stubBlockEditorSettingsRequest(response: HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil))
        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchSettings { _ in
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: expectationTimeout)
    }

    private func validateBlockEditorSettingsResponse(isGlobalStyles: Bool = true) {
        if isGlobalStyles {
            XCTAssertNotNil(self.blog.blockEditorSettings?.rawStyles)
            XCTAssertNotNil(self.blog.blockEditorSettings?.rawFeatures)
        } else {
            XCTAssertNil(self.blog.blockEditorSettings?.rawStyles)
        }

        guard let blockEditorSettings = blog.blockEditorSettings else {
            XCTFail("Block editor settings should exist on the blog at this point")
            return
        }

        guard let colors = blockEditorSettings.colors else {
            XCTFail("Block editor colors should exist at this point")
            return
        }
        XCTAssertGreaterThan(colors.count, 0)

        guard let gradients = blockEditorSettings.gradients else {
            XCTFail("Block editor gradients should exist at this point")
            return
        }
        XCTAssertGreaterThan(gradients.count, 0)
    }

    private func stubBlockEditorSettingsRequest(response: HTTPStubsResponse) {
        let siteID = blog.dotComID ?? 0
        stub(
            condition:
                isMethodGET()
                    && { $0.url?.absoluteString.contains("/wp-block-editor/v1/sites/\(siteID)/settings") == true }
                    && { $0.url?.absoluteString.contains("context=mobile") == true },
            response: { _ in response }
        )
    }
}

extension BlockEditorSettingsServiceTests {

    func mockedData(withFilename filename: String) -> AnyObject {
        let json = Bundle(for: BlockEditorSettingsServiceTests.self).url(forResource: filename, withExtension: "json")!
        let data = try! Data(contentsOf: json)
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
    }

    func setData(withFilename filename: String) {
        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        let mockedResponse = mockedData(withFilename: filename)
        let descriptor = stub(condition: { _ in true }, response: { _ in HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil) })
        service.fetchSettings { _ in
            waitExpectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeout)
        HTTPStubs.removeStub(descriptor)
    }
}
