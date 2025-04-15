import XCTest
@testable import WordPress

final class SupportConfigurationTests: XCTestCase {
    func testSupportConfigurationWhenZendeskDisabled() {
        let configuration = SupportConfiguration.current(zendeskEnabled: false)

        XCTAssertEqual(configuration, .forum)
    }

    func testSupportConfigurationWhenWordPressWithFeatureFlagEnabled() {
        let configuration = SupportConfiguration.current(
            isWordPress: true,
            zendeskEnabled: true
        )

        XCTAssertTrue(configuration == .forum)
    }

    func testSupportConfigurationWhenJetpackWithFeatureFlagEnabled() {
        let configuration = SupportConfiguration.current(
            isWordPress: false,
            zendeskEnabled: true
        )

        XCTAssertTrue(configuration == .zendesk)
    }
}
