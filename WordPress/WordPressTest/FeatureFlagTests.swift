import XCTest
@testable import WordPress

final class FeatureFlagTests: XCTestCase {

    // MARK: Enhanced Site Creation

    func testFeatureFlag_EnhancedSiteCreation_Enabled_ForLocalDeveloperBuildConfiguration() {
        BuildConfiguration.localDeveloper.test {
            let actualValue = FeatureFlag.enhancedSiteCreation.enabled
            XCTAssertTrue(actualValue, "Enhanced site creation should be enabled for .localDeveloper BuildConfiguration")
        }
    }

    func testFeatureFlag_EnhancedSiteCreation_Disabled_ForBranchTestBuildConfiguration() {
        BuildConfiguration.a8cBranchTest.test {
            let actualValue = FeatureFlag.enhancedSiteCreation.enabled
            XCTAssertFalse(actualValue, "Enhanced site creation should be disabled for .a8cBranchTest BuildConfiguration")
        }
    }

    func testFeatureFlag_EnhancedSiteCreation_Disabled_ForPrereleaseTestingBuildConfiguration() {
        BuildConfiguration.a8cPrereleaseTesting.test {
            let actualValue = FeatureFlag.enhancedSiteCreation.enabled
            XCTAssertFalse(actualValue, "Enhanced site creation should be disabled for .a8cPrereleaseTesting BuildConfiguration")
        }
    }

    func testFeatureFlag_EnhancedSiteCreation_Disabled_ForAppStoreBuildConfiguration() {
        BuildConfiguration.appStore.test {
            let actualValue = FeatureFlag.enhancedSiteCreation.enabled
            XCTAssertFalse(actualValue, "Enhanced site creation should be disabled for .appStore BuildConfiguration")
        }
    }
}
