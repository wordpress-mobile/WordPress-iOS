import XCTest
import AutomatticTracks
@testable import WordPress

class SiteCreationStepOrderTests: XCTestCase {

    let featureFlags = FeatureFlagOverrideStore()

    let siteIntentControl = SiteIntentAB.Variant.control
    let siteIntentTreatment = SiteIntentAB.Variant.treatment
    let siteNameControl = Variation.control
    let siteNameTreatment = Variation.treatment(nil)

    func testSiteCreationStepOrderIntentDisabled() throws {

        /// If Site Intent is disabled, Site Name is also disabled

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: false)
        try featureFlags.override(FeatureFlag.siteName, withValue: true)
        let expectedOrder = ["design", "address", "siteAssembly"]

        // When
        var stepOrderer = SiteCreationWizardStepOrderer(
            stepInvoker: MockStepInvoker(),
            siteIntentVariant: siteIntentTreatment,
            siteNameVariant: siteNameTreatment
        )

        // Then
        XCTAssertEqual(expectedOrder, stepOrderer.stepNamesToArray())

        /// If in the Site Intent control group, Site Name is disabled

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)

        // When
        var stepOrdererIntentControl = SiteCreationWizardStepOrderer(
            stepInvoker: MockStepInvoker(),
            siteIntentVariant: siteIntentControl,
            siteNameVariant: siteNameTreatment
        )

        // Then
        XCTAssertEqual(expectedOrder, stepOrdererIntentControl.stepNamesToArray())
    }

    func testSiteCreationStepOrderIntentEnabledNameDisabled() throws {

        /// If in the Site Intent treatment group but not in Site Name, or Site Name is disabled

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        try featureFlags.override(FeatureFlag.siteName, withValue: false)
        let expectedOrder = ["intent", "design", "address", "siteAssembly"]

        // When
        var stepOrderer = SiteCreationWizardStepOrderer(
            stepInvoker: MockStepInvoker(),
            siteIntentVariant: siteIntentTreatment,
            siteNameVariant: siteNameTreatment
        )

        // Then
        XCTAssertEqual(expectedOrder, stepOrderer.stepNamesToArray())

        /// There should be no change if the Site Name feature flag is enabled because Site Name is in the control group

        // Given
        try featureFlags.override(FeatureFlag.siteName, withValue: true)

        // When
        var stepOrdererSiteNameEnabled = SiteCreationWizardStepOrderer(
            stepInvoker: MockStepInvoker(),
            siteIntentVariant: siteIntentTreatment,
            siteNameVariant: siteNameControl
        )

        // Then
        XCTAssertEqual(expectedOrder, stepOrdererSiteNameEnabled.stepNamesToArray())
    }

    func testSiteCreationStepOrderIntentEnabledNameEnabled() throws {

        /// If both features are enabled and in both treatment groups, present both and remove Site Address step

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        let siteIntentVariant = SiteIntentAB.Variant.treatment
        try featureFlags.override(FeatureFlag.siteName, withValue: true)
        let siteNameVariant = Variation.treatment(nil)

        let expectedOrder = ["intent", "name", "design", "siteAssembly"]

        // When
        var stepOrderer = SiteCreationWizardStepOrderer(
            stepInvoker: MockStepInvoker(),
            siteIntentVariant: siteIntentVariant,
            siteNameVariant: siteNameVariant
        )

        // Then
        XCTAssertEqual(expectedOrder, stepOrderer.stepNamesToArray())
    }
}

struct MockStepInvoker: SiteCreationWizardStepInvoker {
    var segmentsStep: WizardStep {
        return MockWizardStep(name: "segments")
    }

    var intentStep: WizardStep {
        return MockWizardStep(name: "intent")
    }

    var nameStep: WizardStep {
        return MockWizardStep(name: "name")
    }

    var designStep: WizardStep {
        return MockWizardStep(name: "design")
    }

    var addressStep: WizardStep {
        return MockWizardStep(name: "address")
    }

    var siteAssemblyStep: WizardStep {
        return MockWizardStep(name: "siteAssembly")
    }
}

struct MockWizardStep: WizardStep {
    let name: String
    var content: UIViewController = UIViewController()
    var delegate: WizardDelegate?
}

private extension SiteCreationWizardStepOrderer {
    mutating func stepNamesToArray() -> [String] {
        return steps.map { ($0 as! MockWizardStep).name }
    }
}
