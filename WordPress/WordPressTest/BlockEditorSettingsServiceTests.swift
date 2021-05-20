import XCTest
import Nimble
@testable import WordPress

class BlockEditorSettingsServiceTests: XCTestCase {

    private let twentytwentyResponseFilename = "get_wp_v2_themes_twentytwenty"
    private let twentytwentyoneResponseFilename = "get_wp_v2_themes_twentytwentyone"

    private var service: BlockEditorSettingsService!
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!
    var mockRemoteApi: MockWordPressComRestApi!
    private var blog: Blog!

    override func setUp() {
        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
        mockRemoteApi = MockWordPressComRestApi()
        blog = ModelTestHelper.insertDotComBlog(context: context)
        blog.dotComID = NSNumber(value: 1)
        blog.account?.authToken = "auth"

        service = BlockEditorSettingsService(blog: blog, remoteAPI: mockRemoteApi, context: context)
    }

    // MARK: Editor `theme_supports` support
    func testThemeSupportsNewTheme() {
        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        let mockedResponse = mockedData(withFilename: twentytwentyoneResponseFilename)
        service.fetchSettings { (hasChanges, result) in
            expect(hasChanges).to(beTrue())
            expect(result).toNot(beNil())
            waitExpectation.fulfill()
        }

        expect(self.mockRemoteApi.getMethodCalled).to(beTrue())
        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1)
        validateResponse()
        expect(self.blog.blockEditorSettings?.checksum).toNot(beNil())
    }

    func testThemeSupportsThemeChange() {
        setData(withFilename: twentytwentyResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        let mockedResponse = mockedData(withFilename: twentytwentyoneResponseFilename)
        service.fetchSettings { (hasChanges, result) in
            expect(hasChanges).to(beTrue())
            expect(result).toNot(beNil())
            waitExpectation.fulfill()
        }

        expect(self.mockRemoteApi.getMethodCalled).to(beTrue())
        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1)
        validateResponse()
        expect(self.blog.blockEditorSettings?.checksum).toNot(equal(originalChecksum))
    }

    func testThemeSupportsThemeIsTheSame() {
        setData(withFilename: twentytwentyoneResponseFilename)
        let originalChecksum = blog.blockEditorSettings?.checksum ?? ""

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        let mockedResponse = mockedData(withFilename: twentytwentyoneResponseFilename)
        service.fetchSettings { (hasChanges, result) in
            expect(hasChanges).to(beFalse())
            expect(result).toNot(beNil())
            waitExpectation.fulfill()
        }

        expect(self.mockRemoteApi.getMethodCalled).to(beTrue())
        mockRemoteApi.successBlockPassedIn!(mockedResponse, HTTPURLResponse())

        waitForExpectations(timeout: 0.1)
        validateResponse()
        expect(self.blog.blockEditorSettings?.checksum).to(equal(originalChecksum))
    }

    private func validateResponse() {
        expect(self.mockRemoteApi.URLStringPassedIn!).to(equal("/wp/v2/sites/1/themes?status=active"))
        expect(self.blog.blockEditorSettings?.colors?.count).to(beGreaterThan(0))
        expect(self.blog.blockEditorSettings?.gradients?.count).to(beGreaterThan(0))
    }
}

extension BlockEditorSettingsServiceTests {

    func mockedData(withFilename filename: String) -> AnyObject {
        let json = Bundle(for: SiteSegmentTests.self).url(forResource: filename, withExtension: "json")!
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
