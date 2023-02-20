import XCTest
@testable import WordPress

final class SupportConfigurationTests: XCTestCase {
    func testSupportConfigurationWhenZendeskDisabled() {
        let configuration = SupportConfiguration.current(zendeskEnabled: false)

        XCTAssertEqual(configuration, .forum)
    }

    func testSupportConfigurationWhenWordPressWithFreePlanAndFeatureFlagEnabled() {
        let configuration = SupportConfiguration.current(
            featureFlagStore: RemoteFeatureFlagStoreMock(isSupportForumEnabled: true),
            isWordPress: true,
            zendeskEnabled: true,
            hasPaidPlan: false
        )

        XCTAssertTrue(configuration == .forum)
    }

    func testSupportConfigurationWhenWordPressWithFreePlanAndFeatureFlagDisabled() {
        let configuration = SupportConfiguration.current(
            featureFlagStore: RemoteFeatureFlagStoreMock(isSupportForumEnabled: false),
            isWordPress: true,
            zendeskEnabled: true,
            hasPaidPlan: false
        )

        XCTAssertTrue(configuration == .zendesk)
    }

    func testSupportConfigurationWhenWordPressWithPaidPlanAndFeatureFlagEnabled() {
        let configuration = SupportConfiguration.current(
            featureFlagStore: RemoteFeatureFlagStoreMock(isSupportForumEnabled: true),
            isWordPress: true,
            zendeskEnabled: true,
            hasPaidPlan: true
        )

        XCTAssertTrue(configuration == .zendesk)
    }

    func testSupportConfigurationWhenJetpackWithFreePlanAndFeatureFlagEnabled() {
        let configuration = SupportConfiguration.current(
            featureFlagStore: RemoteFeatureFlagStoreMock(isSupportForumEnabled: true),
            isWordPress: false,
            zendeskEnabled: true,
            hasPaidPlan: false
        )

        XCTAssertTrue(configuration == .zendesk)
    }

    func testSupportConfigurationWhenJetpackWithPaidPlanAndFeatureFlagEnabled() {
        let configuration = SupportConfiguration.current(
            featureFlagStore: RemoteFeatureFlagStoreMock(isSupportForumEnabled: true),
            isWordPress: false,
            zendeskEnabled: true,
            hasPaidPlan: true
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
