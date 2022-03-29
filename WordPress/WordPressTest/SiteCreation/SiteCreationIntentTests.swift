import XCTest
@testable import WordPress

class SiteCreationIntentTests: XCTestCase {

    struct SiteIntentABMock: SiteIntentABTestable {
        let variant: SiteIntentAB.Variant
    }

    let featureFlags = FeatureFlagOverrideStore()

    func testSiteIntentNotAvailableWhenFeatureFlagOff() throws {

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: false)
        let mockVariant = SiteIntentABMock(variant: .treatment)
        let mockSiteCreator = SiteCreator()

        // When
        let siteIntentStep = SiteIntentStep(siteIntentAB: mockVariant, creator: mockSiteCreator)

        // Then
        XCTAssertNil(siteIntentStep)
    }

    func testSiteIntentAvailableForTreatmentGroup() throws {

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        let mockVariant = SiteIntentABMock(variant: .treatment)
        let mockSiteCreator = SiteCreator()

        // When
        let siteIntentStep = SiteIntentStep(siteIntentAB: mockVariant, creator: mockSiteCreator)

        // Then
        XCTAssertNotNil(siteIntentStep)
    }

    func testSiteIntentNotAvailableForControlGroup() throws {

        // Given
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        let mockVariant = SiteIntentABMock(variant: .control)
        let mockSiteCreator = SiteCreator()

        // When
        let siteIntentStep = SiteIntentStep(siteIntentAB: mockVariant, creator: mockSiteCreator)

        // Then
        XCTAssertNil(siteIntentStep)
    }
}
