import XCTest
import AutomatticTracks
@testable import WordPress

class SiteCreationWizardLauncherTests: XCTestCase {

    private let featureFlags = FeatureFlagOverrideStore()

    private let nameControl = Variation.control
    private let nameTreatment = Variation.treatment(nil)

    /// If Site Intent is disabled, Site Name is also disabled
    func testSiteCreationStepOrderIntentDisabled() throws {

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: false)
        try featureFlags.override(FeatureFlag.siteName, withValue: true)
        let expectedOrder: [SiteCreationStep] = [.design, .address, .siteAssembly]

        // When
        let wizardIntentTreatment = SiteCreationWizardLauncher(nameVariant: nameTreatment)

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
        let wizardNameDisabled = SiteCreationWizardLauncher(nameVariant: nameTreatment)

        // Then
        XCTAssertEqual(expectedOrder, wizardNameDisabled.steps)

        /// There should be no change if the Site Name feature flag is enabled but Site Name is in the control group

        // Given
        try featureFlags.override(FeatureFlag.siteName, withValue: true)

        // When
        let wizardNameControl = SiteCreationWizardLauncher(nameVariant: nameControl)

        // Then
        XCTAssertEqual(expectedOrder, wizardNameControl.steps)
    }

    func testSiteCreationStepOrderIntentEnabledNameEnabled() throws {

        /// If both features are enabled and user is in the Site Name treatment group, present both and remove Site Address step

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        try featureFlags.override(FeatureFlag.siteName, withValue: true)

        let expectedOrder: [SiteCreationStep] = [.intent, .name, .design, .siteAssembly]

        // When
        let wizardBothEnabled = SiteCreationWizardLauncher(nameVariant: nameTreatment)

        // Then
        XCTAssertEqual(expectedOrder, wizardBothEnabled.steps)
    }

    func testSiteNameVariantTracking() throws {

        /// When the Site Creation Wizard Launcher starts, it should fire an event for the variant being tracked

        try runSiteNameVariantTrackingTest(for: nameTreatment)
        try runSiteNameVariantTrackingTest(for: nameControl)
    }
}
