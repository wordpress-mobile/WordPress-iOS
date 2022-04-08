import XCTest
import AutomatticTracks
@testable import WordPress

class SiteCreationWizardLauncherTests: XCTestCase {

    private let featureFlags = FeatureFlagOverrideStore()

    private let intentControl = SiteIntentAB.Variant.control
    private let intentTreatment = SiteIntentAB.Variant.treatment
    private let nameControl = Variation.control
    private let nameTreatment = Variation.treatment(nil)

    func testSiteCreationStepOrderIntentDisabled() throws {

        /// If Site Intent is disabled, Site Name is also disabled

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: false)
        try featureFlags.override(FeatureFlag.siteName, withValue: true)
        let expectedOrder: [SiteCreationStep] = [.design, .address, .siteAssembly]

        // When
        let wizardIntentTreatment = SiteCreationWizardLauncher(intentVariant: intentTreatment, nameVariant: nameTreatment)

        // Then
        XCTAssertEqual(expectedOrder, wizardIntentTreatment.steps)

        /// If in the Site Intent control group, Site Name is disabled

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)

        // When
        let wizardIntentControl = SiteCreationWizardLauncher(intentVariant: intentControl, nameVariant: nameTreatment)

        // Then
        XCTAssertEqual(expectedOrder, wizardIntentControl.steps)
    }

    func testSiteCreationStepOrderIntentEnabledNameDisabled() throws {

        /// If in the Site Intent treatment group but not in Site Name, or Site Name is disabled

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        try featureFlags.override(FeatureFlag.siteName, withValue: false)
        let expectedOrder: [SiteCreationStep] = [.intent, .design, .address, .siteAssembly]

        // When
        let wizardNameDisabled = SiteCreationWizardLauncher(intentVariant: intentTreatment, nameVariant: nameTreatment)

        // Then
        XCTAssertEqual(expectedOrder, wizardNameDisabled.steps)

        /// There should be no change if the Site Name feature flag is enabled because Site Name is in the control group

        // Given
        try featureFlags.override(FeatureFlag.siteName, withValue: true)

        // When
        let wizardNameControl = SiteCreationWizardLauncher(intentVariant: intentTreatment, nameVariant: nameControl)

        // Then
        XCTAssertEqual(expectedOrder, wizardNameControl.steps)
    }

    func testSiteCreationStepOrderIntentEnabledNameEnabled() throws {

        /// If both features are enabled and in both treatment groups, present both and remove Site Address step

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        try featureFlags.override(FeatureFlag.siteName, withValue: true)

        let expectedOrder: [SiteCreationStep] = [.intent, .name, .design, .siteAssembly]

        // When
        let wizardBothEnabled = SiteCreationWizardLauncher(intentVariant: intentTreatment, nameVariant: nameTreatment)

        // Then
        XCTAssertEqual(expectedOrder, wizardBothEnabled.steps)
    }

    func testSiteIntentVariantTracking() throws {
        try runSiteIntentVariantTrackingTest(for: intentTreatment)
        try runSiteIntentVariantTrackingTest(for: intentControl)
    }

    private func runSiteIntentVariantTrackingTest(for variant: SiteIntentAB.Variant) throws {
        TestAnalyticsTracker.setup()

        // Given
        let expectedEvent = WPAnalyticsEvent.enhancedSiteCreationIntentQuestionExperiment.value
        let expectedProperty = variant.tracksProperty
        let variationEventPropertyKey = "variation"

        // When
        let _ = SiteCreationWizardLauncher(intentVariant: variant)

        //Then
        let trackedEvent = try XCTUnwrap(TestAnalyticsTracker.tracked.first (where: { $0.event == expectedEvent }))
        let variation = try XCTUnwrap(trackedEvent.properties[variationEventPropertyKey] as? String)
        XCTAssertEqual(variation, expectedProperty)

        TestAnalyticsTracker.tearDown()
    }
}
