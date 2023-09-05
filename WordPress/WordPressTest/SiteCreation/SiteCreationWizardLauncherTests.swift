import XCTest
import AutomatticTracks
@testable import WordPress

class SiteCreationWizardLauncherTests: XCTestCase {

    private let featureFlags = FeatureFlagOverrideStore()

    func testSiteCreationStepOrderNameDisabled() throws {

        /// Site Name should not be shown if the feature flag is disabled

        // Given
        try featureFlags.override(FeatureFlag.siteName, withValue: false)
        let expectedOrder: [SiteCreationStep] = [.intent, .design, .address, .siteAssembly]

        // When
        let wizardNameDisabled = SiteCreationWizardLauncher()

        // Then
        XCTAssertEqual(expectedOrder, wizardNameDisabled.steps)
    }

    func testSiteCreationStepOrderIntentEnabledNameEnabled() throws {

        /// If both features are enabled and user is in the Site Name treatment group, present both and remove Site Address step

        // Given
        try featureFlags.override(FeatureFlag.siteName, withValue: true)

        let expectedOrder: [SiteCreationStep] = [.intent, .name, .design, .siteAssembly]

        // When
        let wizardBothEnabled = SiteCreationWizardLauncher()

        // Then
        XCTAssertEqual(expectedOrder, wizardBothEnabled.steps)
    }
}
