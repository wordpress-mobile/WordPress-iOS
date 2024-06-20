import XCTest
import OHHTTPStubs
@testable import WordPressKit

class BlockEditorSettingsServiceRemoteTests: XCTestCase {
    private let blockSettingsNOTThemeJSONResponseFilename = "wp-block-editor-v1-settings-success-NotThemeJSON.json"
    private let blockSettingsThemeJSONResponseFilename = "wp-block-editor-v1-settings-success-ThemeJSON.json"
    private let twentytwentyoneResponseFilename = "get_wp_v2_themes_twentytwentyone.json"
    private let testError = NSError(domain: "tests", code: 0, userInfo: nil)
    private let siteID = 1

    private var service: BlockEditorSettingsServiceRemote!

    override func setUp() {
        super.setUp()
        stub(condition: { _ in true }) {
            XCTFail("Unexpected request: \($0)")
            return HTTPStubsResponse(error: URLError(URLError.Code.networkConnectionLost))
        }
        service = BlockEditorSettingsServiceRemote(remoteAPI: .init(site: .dotCom(siteID: UInt64(siteID), bearerToken: "token")))
    }

    func mockedData(withFilename filename: String) -> AnyObject {
        let json = Bundle(for: BlockEditorSettingsServiceRemoteTests.self).url(forResource: filename, withExtension: nil)!
        let data = try! Data(contentsOf: json)
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
    }
}

// MARK: Editor `theme_supports` support
extension BlockEditorSettingsServiceRemoteTests {

    func testFetchThemeSuccess() {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/wp/v2/sites/1/themes") && containsQueryParams(["status": "active"])) { _ in
            fixture(filePath: OHPathForFile(self.twentytwentyoneResponseFilename, Self.self)!, headers: ["Content-Type": "application/json"])
        }

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchTheme { response in
            switch response {
            case .success(let result):
                XCTAssertNotNil(result)
                XCTAssertFalse(result!.checksum.isEmpty)
                XCTAssertGreaterThan(result!.themeSupport!.colors!.count, 0)
                XCTAssertGreaterThan(result!.themeSupport!.gradients!.count, 0)
                XCTAssertTrue(result!.themeSupport!.blockTemplates)
            case .failure:
                XCTFail("This payload should parse successfully")
            }
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: 0.3)
    }

    func testFetchThemeNoGradients() {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/wp/v2/sites/1/themes") && containsQueryParams(["status": "active"])) { _ in
            var mockedResponse = self.mockedData(withFilename: self.twentytwentyoneResponseFilename) as! [[String: Any]]

            // Clear out Gradients
            var theme = mockedResponse[0]
            var themeSupport = theme[RemoteEditorTheme.CodingKeys.themeSupport.stringValue] as! [String: Any]
            themeSupport[RemoteEditorThemeSupport.CodingKeys.gradients.stringValue] = "false"
            theme[RemoteEditorTheme.CodingKeys.themeSupport.stringValue] = themeSupport
            mockedResponse[0] = theme

            return HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil)
        }

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchTheme { response in
            switch response {
            case .success(let result):
                XCTAssertNotNil(result)
                XCTAssertFalse(result!.checksum.isEmpty)
                XCTAssertGreaterThan(result!.themeSupport!.colors!.count, 0)
                XCTAssertNil(result!.themeSupport!.gradients)
            case .failure:
                XCTFail("This payload should parse successfully")
            }
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: 0.3)
    }

    func testFetchThemeNoColors() {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/wp/v2/sites/1/themes") && containsQueryParams(["status": "active"])) { _ in
            var mockedResponse = self.mockedData(withFilename: self.twentytwentyoneResponseFilename) as! [[String: Any]]

            // Clear out Colors
            var theme = mockedResponse[0]
            var themeSupport = theme[RemoteEditorTheme.CodingKeys.themeSupport.stringValue] as! [String: Any]
            themeSupport[RemoteEditorThemeSupport.CodingKeys.colors.stringValue] = "false"

            themeSupport[RemoteEditorThemeSupport.CodingKeys.blockTemplates.stringValue] = "false"
            theme[RemoteEditorTheme.CodingKeys.themeSupport.stringValue] = themeSupport

            mockedResponse[0] = theme

            return HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil)
        }

        let waitExpectation = expectation(description: "Theme should be successfully fetched")

        service.fetchTheme { response in
            switch response {
            case .success(let result):
                XCTAssertNotNil(result)
                XCTAssertFalse(result!.checksum.isEmpty)
                XCTAssertNil(result!.themeSupport!.colors)
                XCTAssertGreaterThan(result!.themeSupport!.gradients!.count, 0)
                XCTAssertFalse(result!.themeSupport!.blockTemplates)
            case .failure:
                XCTFail("This payload should parse successfully")
            }
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: 0.3)
    }

    func testFetchThemeNoThemeSupport() {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/wp/v2/sites/1/themes") && containsQueryParams(["status": "active"])) { _ in
            var mockedResponse = self.mockedData(withFilename: self.twentytwentyoneResponseFilename) as! [[String: Any]]
            var theme = mockedResponse[0]
            var themeSupport = theme[RemoteEditorTheme.CodingKeys.themeSupport.stringValue] as! [String: Any]

            themeSupport.removeValue(forKey: RemoteEditorThemeSupport.CodingKeys.blockTemplates.stringValue)
            theme[RemoteEditorTheme.CodingKeys.themeSupport.stringValue] = themeSupport
            mockedResponse[0] = theme

            return HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil)
        }

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchTheme { response in
            switch response {
            case .success(let result):
                XCTAssertFalse(result!.themeSupport!.blockTemplates)
            case .failure:
                XCTFail("This payload should parse successfully")
            }
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: 0.3)
    }

    func testFetchThemeFailure() {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/wp/v2/sites/1/themes") && containsQueryParams(["status": "active"])) { _ in
            HTTPStubsResponse(jsonObject: [String: String](), statusCode: 400, headers: nil)
        }

        let waitExpectation = expectation(description: "Theme should be successfully fetched")
        service.fetchTheme { response in
            switch response {
            case .success:
                XCTFail("This Request should have failed")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: 0.3)
    }

}

// MARK: Editor Global Styles support
extension BlockEditorSettingsServiceRemoteTests {

    func testFetchBlockEditorSettingsInvalidJSON() {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/wp-block-editor/v1/sites/1/settings") && containsQueryParams(["context": "mobile"])) { _ in
            HTTPStubsResponse(jsonObject: ["invalid-json"], statusCode: 200, headers: nil)
        }

        let waitExpectation = expectation(description: "Block Settings should be successfully fetched")
        service.fetchBlockEditorSettings { response in
            switch response {
            case .success(let result):
                XCTAssertNil(result)
            case .failure:
                XCTFail("This payload should parse successfully")
            }
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: 0.3)
    }

    func testFetchBlockEditorSettingsNotThemeJSON() {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/wp-block-editor/v1/sites/1/settings") && containsQueryParams(["context": "mobile"])) { _ in
            fixture(filePath: OHPathForFile(self.blockSettingsNOTThemeJSONResponseFilename, Self.self)!, headers: ["Content-Type": "application/json"])
        }

        let waitExpectation = expectation(description: "Block Settings should be successfully fetched")
        service.fetchBlockEditorSettings { response in
            switch response {
            case .success(let result):
                self.validateFetchBlockEditorSettingsResults(result)
                XCTAssertNil(result!.rawStyles)
                XCTAssertFalse(result!.isFSETheme)
            case .failure:
                XCTFail("This payload should parse successfully")
            }
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: 0.3)
    }

    func testFetchBlockEditorSettingsThemeJSON() {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/wp-block-editor/v1/sites/1/settings") && containsQueryParams(["context": "mobile"])) { _ in
            fixture(filePath: OHPathForFile(self.blockSettingsThemeJSONResponseFilename, Self.self)!, headers: ["Content-Type": "application/json"])
        }

        let waitExpectation = expectation(description: "Block Settings should be successfully fetched")
        service.fetchBlockEditorSettings { response in
            switch response {
            case .success(let result):
                self.validateFetchBlockEditorSettingsResults(result)

                XCTAssertNotNil(result!.rawStyles)
                XCTAssertTrue(result!.isFSETheme)
                let gssRawJson = result!.rawStyles!.data(using: .utf8)!
                let vaildJson = try? JSONSerialization.jsonObject(with: gssRawJson, options: [])
                XCTAssertNotNil(vaildJson)
            case .failure:
                XCTFail("This payload should parse successfully")
            }
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: 0.3)
    }

    func testFetchBlockEditorSettingsNoFSETheme() {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/wp-block-editor/v1/sites/1/settings") && containsQueryParams(["context": "mobile"])) { _ in
            var mockedResponse = self.mockedData(withFilename: self.blockSettingsThemeJSONResponseFilename) as! [String: Any]
            mockedResponse.removeValue(forKey: RemoteBlockEditorSettings.CodingKeys.isFSETheme.stringValue)

            return HTTPStubsResponse(jsonObject: mockedResponse, statusCode: 200, headers: nil)
        }

        let waitExpectation = expectation(description: "Block Settings should be successfully fetched")

        service.fetchBlockEditorSettings { response in
            switch response {
            case .success(let result):
                self.validateFetchBlockEditorSettingsResults(result)
                XCTAssertFalse(result!.isFSETheme)
            case .failure:
                XCTFail("This payload should parse successfully")
            }
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: 0.3)
    }

    func testFetchBlockEditorSettingsThemeJSON_ConsistentChecksum() {
        let json = Bundle(for: BlockEditorSettingsServiceRemoteTests.self).url(forResource: blockSettingsThemeJSONResponseFilename, withExtension: nil)!
        let data = try! Data(contentsOf: json)

        let blockEditorSettings1 = try? JSONDecoder().decode(RemoteBlockEditorSettings.self, from: data)
        let blockEditorSettings2 = try? JSONDecoder().decode(RemoteBlockEditorSettings.self, from: data)
        XCTAssertEqual(blockEditorSettings1!.checksum, blockEditorSettings2!.checksum)
    }

    func testFetchBlockEditorSettingsFailure() {
        stub(condition: isHost("public-api.wordpress.com") && isPath("/wp-block-editor/v1/sites/1/settings") && containsQueryParams(["context": "mobile"])) { _ in
            HTTPStubsResponse(jsonObject: [String: String](), statusCode: 400, headers: nil)
        }

        let waitExpectation = expectation(description: "Block Settings should be successfully fetched")
        service.fetchBlockEditorSettings { response in
            switch response {
            case .success:
                XCTFail("This Request should have failed")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: 0.3)
    }

    func testFetchBlockEditorSettingsOrgEndpoint() {
        stub(condition: isHost("example.com") && isPath("/wp-json/wp-block-editor/v1/settings") && containsQueryParams(["context": "mobile"])) { _ in
            fixture(filePath: OHPathForFile(self.blockSettingsThemeJSONResponseFilename, Self.self)!, headers: ["Content-Type": "application/json"])
        }

        let waitExpectation = expectation(description: "Block Settings should be successfully fetched")
        service = BlockEditorSettingsServiceRemote(remoteAPI: WordPressOrgRestApi(apiBase: URL(string: "https://example.com/wp-json/")!))
        service.fetchBlockEditorSettings { (_) in
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: 0.3)
    }

    // The only difference between this test and the one above (testFetchBlockEditorSettingsOrgEndpoint) is this
    // test's `WordPressOrgRestApi` is instantiated using a url ends with '/wp-json', instead of '/wp-json/'.
    // This small difference ends up with an incorrect API request being sent out. Hence this test is marked as an
    // "expected failure".
    func testFetchBlockEditorSettingsOrgEndpointFailure() {
        stub(condition: isHost("example.com") && isPath("/wp-json/wp-block-editor/v1/settings") && containsQueryParams(["context": "mobile"])) { _ in
            fixture(filePath: OHPathForFile(self.blockSettingsThemeJSONResponseFilename, Self.self)!, headers: ["Content-Type": "application/json"])
        }

        let waitExpectation = expectation(description: "Block Settings should be successfully fetched")
        service = BlockEditorSettingsServiceRemote(remoteAPI: WordPressOrgRestApi(apiBase: URL(string: "https://example.com/wp-json")!))
        service.fetchBlockEditorSettings { (_) in
            waitExpectation.fulfill()
        }

        wait(for: [waitExpectation], timeout: 0.3)
    }

    private func validateFetchBlockEditorSettingsResults(_ result: RemoteBlockEditorSettings?) {
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.checksum.isEmpty)

        XCTAssertGreaterThan(result!.colors!.count, 0)
        XCTAssertGreaterThan(result!.gradients!.count, 0)

        XCTAssertNotNil(result!.rawFeatures)
        let themeRawJson = result!.rawFeatures!.data(using: .utf8)!
        let vaildJson = try? JSONSerialization.jsonObject(with: themeRawJson, options: [])
        XCTAssertNotNil(vaildJson)
    }
}
