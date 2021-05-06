import XCTest
import Nimble
@testable import WordPress

class BlockEditorSettingsServiceTests: XCTestCase {
    private let twentytwentyResponseFilename = "get_wp_v2_themes_twentytwenty"
    private let twentytwentyoneResponseFilename = "get_wp_v2_themes_twentytwentyone"
    private let blockSettingsNOTThemeJSONResponseFilename = "wp-block-editor-v1-settings-success-NotThemeJSON"
    private let blockSettingsThemeJSONResponseFilename = "wp-block-editor-v1-settings-success-ThemeJSON"

    private var service: BlockEditorSettingsService!
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!
    var mockRemoteApi: MockWordPressComRestApi!
    var gssOriginalValue: Bool!
    private var blog: Blog!

    override func setUp() {
        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
        mockRemoteApi = MockWordPressComRestApi()
        blog = ModelTestHelper.insertDotComBlog(context: context)
        blog.dotComID = NSNumber(value: 1)
        blog.account?.authToken = "auth"

        service = BlockEditorSettingsService(blog: blog, remoteAPI: mockRemoteApi, context: context)

        gssOriginalValue = FeatureFlag.globalStyleSettings.enabled
    }

    override func tearDown() {
        super.tearDown()
        try? FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: gssOriginalValue)
    }

    // MARK: Editor `theme_supports` support
    func testThemeSupportsNewTheme() {
        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        let mockedResponse = mockedData(withFilename: twentytwentyoneResponseFilename)
        service.fetchSettings { (hasChanges, result) in
            XCTAssertTrue(hasChanges)
            XCTAssertNotNil(result)
            waitExpectation.fulfill()
        }

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1)
        validateThemeResponse()
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
    }

    func testThemeSupportsThemeChange() {
        setData(withFilename: twentytwentyResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        let mockedResponse = mockedData(withFilename: twentytwentyoneResponseFilename)
        service.fetchSettings { (hasChanges, result) in
            XCTAssertTrue(hasChanges)
            XCTAssertNotNil(result)
            waitExpectation.fulfill()
        }

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1)
        validateThemeResponse()
        XCTAssertNotEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    func testThemeSupportsThemeIsTheSame() {
        setData(withFilename: twentytwentyoneResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        let mockedResponse = mockedData(withFilename: twentytwentyoneResponseFilename)
        service.fetchSettings { (hasChanges, result) in
            XCTAssertFalse(hasChanges)
            XCTAssertNotNil(result)
            waitExpectation.fulfill()
        }
        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1)
        validateThemeResponse()
        XCTAssertEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    private func validateThemeResponse() {
        XCTAssertTrue(self.mockRemoteApi.getMethodCalled)
        XCTAssertEqual(self.mockRemoteApi.URLStringPassedIn!, "/wp/v2/sites/1/themes")
        XCTAssertEqual((self.mockRemoteApi.parametersPassedIn as! [String: String])["status"], "active")
        XCTAssertGreaterThan(self.blog.blockEditorSettings!.colors!.count, 0)
        XCTAssertGreaterThan(self.blog.blockEditorSettings!.gradients!.count, 0)
    }

    // MARK: Editor Global Styles support
    func testFetchBlockEditorSettingsNotThemeJSON() {
        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)
        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        let mockedResponse = mockedData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        service.fetchSettings { (hasChanges, result) in
            XCTAssertTrue(hasChanges)
            XCTAssertNotNil(result)
            waitExpectation.fulfill()
        }

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1)
        validateBlockEditorSettingsResponse(isGlobalStyles: false)
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
    }

    func testFetchBlockEditorSettingsThemeJSON() {
        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)
        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        let mockedResponse = mockedData(withFilename: blockSettingsThemeJSONResponseFilename)
        service.fetchSettings { (hasChanges, result) in
            XCTAssertTrue(hasChanges)
            XCTAssertNotNil(result)
            waitExpectation.fulfill()
        }

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1)
        validateBlockEditorSettingsResponse(isGlobalStyles: true)
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
    }

    func testFetchBlockEditorSettingsThemeJSONChangeFromOldEndpointToNew() {
        setData(withFilename: twentytwentyoneResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)
        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        let mockedResponse = mockedData(withFilename: blockSettingsThemeJSONResponseFilename)
        service.fetchSettings { (hasChanges, result) in
            XCTAssertTrue(hasChanges)
            XCTAssertNotNil(result)
            waitExpectation.fulfill()
        }

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1)
        validateBlockEditorSettingsResponse(isGlobalStyles: true)
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
        XCTAssertNotEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }


    func testFetchBlockEditorSettingsThemeJSONChangeSettings() {
        setData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)
        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        let mockedResponse = mockedData(withFilename: blockSettingsThemeJSONResponseFilename)
        service.fetchSettings { (hasChanges, result) in
            XCTAssertTrue(hasChanges)
            XCTAssertNotNil(result)
            waitExpectation.fulfill()
        }

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1)
        validateBlockEditorSettingsResponse(isGlobalStyles: true)
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
        XCTAssertNotEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    func testFetchBlockEditorSettingsNoChange() {
        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)

        setData(withFilename: blockSettingsThemeJSONResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        let mockedResponse = mockedData(withFilename: blockSettingsThemeJSONResponseFilename)
        service.fetchSettings { (hasChanges, result) in
            XCTAssertFalse(hasChanges)
            XCTAssertNotNil(result)
            waitExpectation.fulfill()
        }

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1)
        validateBlockEditorSettingsResponse(isGlobalStyles: true)
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
        XCTAssertEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    private func validateBlockEditorSettingsResponse(isGlobalStyles: Bool) {
        XCTAssertTrue(self.mockRemoteApi.getMethodCalled)
        XCTAssertEqual(self.mockRemoteApi.URLStringPassedIn!, "/__experimental/wp-block-editor/v1/settings")
        XCTAssertEqual((self.mockRemoteApi.parametersPassedIn as! [String: String])["context"], "site-editor")

        if isGlobalStyles {
            XCTAssertNotNil(self.blog.blockEditorSettings?.rawGlobalStylesBaseStyles)
        } else {
            XCTAssertGreaterThan(self.blog.blockEditorSettings!.colors!.count, 0)
            XCTAssertGreaterThan(self.blog.blockEditorSettings!.gradients!.count, 0)
        }
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
        service.fetchSettings { (hasChanges, result) in
            waitExpectation.fulfill()
        }
        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())
        waitForExpectations(timeout: 0.1)
    }
}
