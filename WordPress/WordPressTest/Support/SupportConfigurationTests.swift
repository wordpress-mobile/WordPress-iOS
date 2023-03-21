import XCTest
@testable import WordPress

final class SupportConfigurationTests: XCTestCase {
    func testSupportConfigurationWhenZendeskDisabled() {
        let configuration = SupportConfiguration.current(zendeskEnabled: false)

        XCTAssertEqual(configuration, .forum)
    }

    func testSupportConfigurationWhenWordPressWithFeatureFlagEnabled() {
        let configuration = SupportConfiguration.current(
            featureFlagStore: RemoteFeatureFlagStoreMock(isSupportForumEnabled: true),
            isWordPress: true,
            zendeskEnabled: true
        )

        XCTAssertTrue(configuration == .forum)
    }

    func testSupportConfigurationWhenWordPressWithFeatureFlagDisabled() {
        let configuration = SupportConfiguration.current(
            featureFlagStore: RemoteFeatureFlagStoreMock(isSupportForumEnabled: false),
            isWordPress: true,
            zendeskEnabled: true
        )

        XCTAssertTrue(configuration == .zendesk)
    }

    func testSupportConfigurationWhenJetpackWithFeatureFlagEnabled() {
        let configuration = SupportConfiguration.current(
            featureFlagStore: RemoteFeatureFlagStoreMock(isSupportForumEnabled: true),
            isWordPress: false,
            zendeskEnabled: true
        )

        XCTAssertTrue(configuration == .zendesk)
    }

    func testSupportConfigurationWhenJetpackWithFeatureFlagDisabled() {
        let configuration = SupportConfiguration.current(
            featureFlagStore: RemoteFeatureFlagStoreMock(isSupportForumEnabled: false),
            isWordPress: false,
            zendeskEnabled: true
        )

        XCTAssertTrue(configuration == .zendesk)
    }
}

private extension SupportConfigurationTests {
    class RemoteFeatureFlagStoreMock: RemoteFeatureFlagStore {
        var isSupportForumEnabled = false

        init(isSupportForumEnabled: Bool) {
            self.isSupportForumEnabled = isSupportForumEnabled
            super.init()
        }

        override func value(for flag: OverrideableFlag) -> Bool {
            if flag.remoteKey == FeatureFlag.wordPressSupportForum.remoteKey {
                return isSupportForumEnabled
            }

            return false
        }
    }
}
