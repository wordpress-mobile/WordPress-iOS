import XCTest
import AutomatticTracks
@testable import WordPress

class SiteCreationWizardLauncherTests: XCTestCase {

    private let featureFlags = FeatureFlagOverrideStore()

    /// If Site Intent is disabled, Site Name is also disabled
    func testSiteCreationStepOrderIntentDisabled() throws {

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: false)
        try featureFlags.override(FeatureFlag.siteName, withValue: true)
        let expectedOrder: [SiteCreationStep] = [.design, .address, .siteAssembly]

        // When
        let wizardIntentTreatment = SiteCreationWizardLauncher()

        // Then
        XCTAssertEqual(expectedOrder, wizardIntentTreatment.steps)
    }

    func testSiteCreationStepOrderNameDisabled() throws {

        /// Site Name should not be shown if the feature flag is disabled

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
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
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        try featureFlags.override(FeatureFlag.siteName, withValue: true)

        let expectedOrder: [SiteCreationStep] = [.intent, .name, .design, .siteAssembly]

        // When
        let wizardBothEnabled = SiteCreationWizardLauncher()

        // Then
        XCTAssertEqual(expectedOrder, wizardBothEnabled.steps)
    }
}
