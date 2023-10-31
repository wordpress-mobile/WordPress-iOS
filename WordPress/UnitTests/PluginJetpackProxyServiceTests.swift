import XCTest
@testable import WordPress

class PluginJetpackProxyServiceTests: XCTestCase {

    private let siteID = 1001
    private let api = MockWordPressComRestApi()

    private var remote: JetpackProxyServiceRemote {
        .init(wordPressComRestApi: api)
    }

    lazy private var service: PluginJetpackProxyService = {
        .init(remote: remote)
    }()

    // MARK: Tests

    func test_installPlugin_shouldAssignCorrectParameters() {
        // Arrange
        let expectedPath = "/wp/v2/plugins"
        let expectedMethod = "post"
        let expectedSlug = "jetpack"
        let expectedStatus = "active"

        // Act
        service.installPlugin(for: siteID, pluginSlug: expectedSlug, active: true) { _ in }

        // Assert
        guard let params = api.parametersPassedIn as? [String: AnyHashable] else {
            XCTFail()
            return
        }

        // verify that the path is correct
        XCTAssertEqual(params["path"], "\(expectedPath)&_method=\(expectedMethod)")

        // verify that the body is correct
        guard let bodyJsonString = params["body"] as? String,
              let data = bodyJsonString.data(using: .utf8),
              let dictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            XCTFail("Body parameter expected to exist.")
            return
        }
        XCTAssertEqual(dictionary["slug"], expectedSlug)
        XCTAssertEqual(dictionary["status"], expectedStatus)

    }
}
