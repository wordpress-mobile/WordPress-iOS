import XCTest
import Nimble
@testable import WordPress

class BlockEditorSettingsServiceTests: XCTestCase {
    let expectationTimeout = TimeInterval(1)
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
        context = contextManager.mainContext
        mockRemoteApi = MockWordPressComRestApi()
        blog = BlogBuilder(context)
            .with(wordPressVersion: "5.8")
            .withAnAccount()
            .build()

        service = BlockEditorSettingsService(blog: blog, remoteAPI: mockRemoteApi, context: context)

        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: false)
    }

    // MARK: Editor `theme_supports` support
    func testThemeSupportsNewTheme() {
        let mockedResponse = mockedData(withFilename: twentytwentyoneResponseFilename)
        let waitExpectation = expectation(description: "Theme should be successfully fetched (0)")
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

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: expectationTimeout)
        validateThemeResponse()
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
    }

    func testThemeSupportsThemeChange() {
        setData(withFilename: twentytwentyResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        let mockedResponse = mockedData(withFilename: twentytwentyoneResponseFilename)
        let waitExpectation = expectation(description: "Theme should be successfully fetched (1)")
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

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: expectationTimeout)
        validateThemeResponse()
        XCTAssertNotEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    func testThemeSupportsThemeIsTheSame() {
        setData(withFilename: twentytwentyoneResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""
        let mockedResponse = mockedData(withFilename: twentytwentyoneResponseFilename)

        let waitExpectation = expectation(description: "Theme should be successfully fetched (2)")
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
        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: expectationTimeout)
        validateThemeResponse()
        XCTAssertEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    private func validateThemeResponse() {
        let siteID = blog.dotComID ?? 0
        XCTAssertTrue(self.mockRemoteApi.getMethodCalled)
        XCTAssertEqual(self.mockRemoteApi.URLStringPassedIn!, "/wp/v2/sites/\(siteID)/themes")
        XCTAssertEqual((self.mockRemoteApi.parametersPassedIn as! [String: String])["status"], "active")
        XCTAssertGreaterThan(self.blog.blockEditorSettings!.colors!.count, 0)
        XCTAssertGreaterThan(self.blog.blockEditorSettings!.gradients!.count, 0)
    }

    // MARK: Editor Global Styles support
    func testFetchBlockEditorSettingsNotThemeJSON() {
        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)
        let mockedResponse = mockedData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        let waitExpectation = expectation(description: "Theme should be successfully fetched (3)")
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

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: expectationTimeout)
        validateBlockEditorSettingsResponse(isGlobalStyles: false)
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
    }

    func testFetchBlockEditorSettingsThemeJSON() {
        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)
        let mockedResponse = mockedData(withFilename: blockSettingsThemeJSONResponseFilename)
        let waitExpectation = expectation(description: "Theme should be successfully fetched (4)")
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

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: expectationTimeout)
        validateBlockEditorSettingsResponse()
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
    }

    func testFetchBlockEditorSettingsThemeJSONChangeFromOldEndpointToNew() {
        setData(withFilename: twentytwentyoneResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)
        let mockedResponse = mockedData(withFilename: blockSettingsThemeJSONResponseFilename)
        let waitExpectation = expectation(description: "Theme should be successfully fetched (5)")
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

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: expectationTimeout)
        validateBlockEditorSettingsResponse()
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
        XCTAssertNotEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }


    func testFetchBlockEditorSettingsThemeJSONChangeSettings() {
        setData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)
        let mockedResponse = mockedData(withFilename: blockSettingsThemeJSONResponseFilename)
        let waitExpectation = expectation(description: "Theme should be successfully fetched (6)")
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

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: expectationTimeout)
        validateBlockEditorSettingsResponse()
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
        XCTAssertNotEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    func testFetchBlockEditorSettingsNoChange() {
        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)

        setData(withFilename: blockSettingsThemeJSONResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        let mockedResponse = mockedData(withFilename: blockSettingsThemeJSONResponseFilename)
        let waitExpectation = expectation(description: "Theme should be successfully fetched (7)")
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

        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: expectationTimeout)
        validateBlockEditorSettingsResponse()
        XCTAssertNotNil(self.blog.blockEditorSettings?.checksum)
        XCTAssertEqual(self.blog.blockEditorSettings?.checksum, originalChecksum)
    }

    func testFetchBlockEditorSettings_OrgSite_NoPlugin() {
        blog = BlogBuilder(context).build()

        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)
        let mockedResponse = mockedData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        let mockOrgRemoteApi = MockWordPressOrgRestApi()
        service = BlockEditorSettingsService(blog: blog, remoteAPI: mockOrgRemoteApi, context: context)

        let waitExpectation = expectation(description: "Theme should be successfully fetched (8)")
        service.fetchSettings { _ in
            waitExpectation.fulfill()
        }

        // The app will call the none-experimental path first but fail because of compatibility reasons
        mockOrgRemoteApi.completionPassedIn!(.failure(NSError(domain: "test", code: 404, userInfo: nil)), HTTPURLResponse())
        // The app will then retry the wp/v2/themes path.
        mockOrgRemoteApi.completionPassedIn!(.success(mockedResponse), HTTPURLResponse())
        waitForExpectations(timeout: expectationTimeout)

        XCTAssertTrue(mockOrgRemoteApi.getMethodCalled)
        XCTAssertEqual(mockOrgRemoteApi.URLStringPassedIn!, "/wp/v2/themes")
        XCTAssertEqual((mockOrgRemoteApi.parametersPassedIn as! [String: String])["status"], "active")
    }

    func testFetchBlockEditorSettings_OrgSite() {
        blog = BlogBuilder(context).build()

        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)
        let mockedResponse = mockedData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        let mockOrgRemoteApi = MockWordPressOrgRestApi()
        service = BlockEditorSettingsService(blog: blog, remoteAPI: mockOrgRemoteApi, context: context)

        let waitExpectation = expectation(description: "Theme should be successfully fetched (9)")
        service.fetchSettings { _ in
            waitExpectation.fulfill()
        }
        mockOrgRemoteApi.completionPassedIn!(.success(mockedResponse), HTTPURLResponse())
        waitForExpectations(timeout: expectationTimeout)

        XCTAssertTrue(mockOrgRemoteApi.getMethodCalled)
        XCTAssertEqual(mockOrgRemoteApi.URLStringPassedIn!, "/wp-block-editor/v1/settings")
        XCTAssertEqual((mockOrgRemoteApi.parametersPassedIn as! [String: String])["context"], "mobile")
    }

    func testFetchBlockEditorSettings_Com5_8Site() {
        blog = BlogBuilder(context)
            .withAnAccount()
            .build()

        service = BlockEditorSettingsService(blog: blog, remoteAPI: mockRemoteApi, context: context)

        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)
        let mockedResponse = mockedData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        let waitExpectation = expectation(description: "Theme should be successfully fetched (10)")
        service.fetchSettings { _ in
            waitExpectation.fulfill()
        }
        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())
        waitForExpectations(timeout: expectationTimeout)

        XCTAssertTrue(self.mockRemoteApi.getMethodCalled)
        XCTAssertEqual(self.mockRemoteApi.URLStringPassedIn!, "/wp-block-editor/v1/sites/\(blog.dotComID!.intValue)/settings")
        XCTAssertEqual((self.mockRemoteApi.parametersPassedIn as! [String: String])["context"], "mobile")
    }

    func testFetchBlockEditorSettings_Com5_9Site() {
        try! FeatureFlagOverrideStore().override(FeatureFlag.globalStyleSettings, withValue: true)
        let mockedResponse = mockedData(withFilename: blockSettingsNOTThemeJSONResponseFilename)
        let waitExpectation = expectation(description: "Theme should be successfully fetched (11)")
        service.fetchSettings { _ in
            waitExpectation.fulfill()
        }
        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())
        waitForExpectations(timeout: expectationTimeout)

        XCTAssertTrue(self.mockRemoteApi.getMethodCalled)
        XCTAssertEqual(self.mockRemoteApi.URLStringPassedIn!, "/wp-block-editor/v1/sites/\(blog.dotComID!.intValue)/settings")
        XCTAssertEqual((self.mockRemoteApi.parametersPassedIn as! [String: String])["context"], "mobile")
    }

    private func validateBlockEditorSettingsResponse(isGlobalStyles: Bool = true) {
        XCTAssertTrue(self.mockRemoteApi.getMethodCalled)
        XCTAssertEqual(self.mockRemoteApi.URLStringPassedIn!, "/wp-block-editor/v1/sites/\(blog.dotComID!.intValue)/settings")
        XCTAssertEqual((self.mockRemoteApi.parametersPassedIn as! [String: String])["context"], "mobile")

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
}

extension BlockEditorSettingsServiceTests {

    func mockedData(withFilename filename: String) -> AnyObject {
        let json = Bundle(for: BlockEditorSettingsServiceTests.self).url(forResource: filename, withExtension: "json")!
        let data = try! Data(contentsOf: json)
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
    }

    func setData(withFilename filename: String) {
        let waitExpectation = expectation(description: "Theme should be successfully fetched (12)")
        let mockedResponse = mockedData(withFilename: filename)
        service.fetchSettings { _ in
            waitExpectation.fulfill()
        }
        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())
        waitForExpectations(timeout: expectationTimeout)
    }
}
