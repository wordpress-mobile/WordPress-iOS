import XCTest
import AutomatticTracks
@testable import WordPress

class SiteCreationNameTests: XCTestCase {
    let featureFlags = FeatureFlagOverrideStore()

    /// If the Site Name feature flag is off the Site Name step shouldn't be shown
    func testSiteNameNotAvailableWhenFeatureFlagOff() throws {

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        try featureFlags.override(FeatureFlag.siteName, withValue: false)

        let intentVariation = SiteCreationIntentTests.SiteIntentABMock(variant: .treatment).variant
        let nameVariation = Variation.treatment(nil)
        let mockSiteCreator = SiteCreator()

        // When
        let siteNameStep = SiteNameStep(
            siteIntentVariation: intentVariation,
            siteNameVariation: nameVariation,
            creator: mockSiteCreator
        )

        // Then
        XCTAssertNil(siteNameStep)
    }

    /// If the user is in the Site Name and Site Intent treatment groups and both feature flags are enabled, the Site Name step should be shown
    func testSiteNameAvailableForTreatmentGroup() throws {

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        try featureFlags.override(FeatureFlag.siteName, withValue: true)

        let intentVariation = SiteCreationIntentTests.SiteIntentABMock(variant: .treatment).variant
        let nameVariation = Variation.treatment(nil)
        let mockSiteCreator = SiteCreator()

        // When
        let siteNameStep = SiteNameStep(
            siteIntentVariation: intentVariation,
            siteNameVariation: nameVariation,
            creator: mockSiteCreator
        )

        // Then
        XCTAssertNotNil(siteNameStep)
    }

    /// If the user is in the Site Name control group, the Site Name step shouldn't be shown
    func testSiteNameNotAvailableForControlGroup() throws {

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        try featureFlags.override(FeatureFlag.siteName, withValue: true)

        let intentVariation = SiteCreationIntentTests.SiteIntentABMock(variant: .treatment).variant
        let nameVariation = Variation.control
        let mockSiteCreator = SiteCreator()

        // When
        let siteNameStep = SiteNameStep(
            siteIntentVariation: intentVariation,
            siteNameVariation: nameVariation,
            creator: mockSiteCreator
        )

        // Then
        XCTAssertNil(siteNameStep)
    }

    /// If the user is in the Site Intent control group, the Site Name step shouldn't be shown
    func testSiteNameNotAvailableForIntentControlGroup() throws {

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        try featureFlags.override(FeatureFlag.siteName, withValue: true)

        let intentVariation = SiteCreationIntentTests.SiteIntentABMock(variant: .control).variant
        let nameVariation = Variation.treatment(nil)
        let mockSiteCreator = SiteCreator()

        // When
        let siteNameStep = SiteNameStep(
            siteIntentVariation: intentVariation,
            siteNameVariation: nameVariation,
            creator: mockSiteCreator
        )

        // Then
        XCTAssertNil(siteNameStep)
    }

    /// If the Site Intent feature flag is disabled the Site Name step shouldn't be shown
    func testSiteNameNotAvailableWhenIntentFeatureFlagOff() throws {

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: false)
        try featureFlags.override(FeatureFlag.siteName, withValue: true)

        let intentVariation = SiteCreationIntentTests.SiteIntentABMock(variant: .treatment).variant
        let nameVariation = Variation.treatment(nil)
        let mockSiteCreator = SiteCreator()

        // When
        let siteNameStep = SiteNameStep(
            siteIntentVariation: intentVariation,
            siteNameVariation: nameVariation,
            creator: mockSiteCreator
        )

        // Then
        XCTAssertNil(siteNameStep)
    }
}
