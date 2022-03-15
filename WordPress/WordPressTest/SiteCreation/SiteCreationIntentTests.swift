import XCTest
@testable import WordPress

class SiteCreationIntentTests: XCTestCase {

    class SiteIntentABMock: SiteIntentABTestable {
        let variant: SiteIntentAB.Variant

        init(override: SiteIntentAB.Variant) {
            self.variant = override
        }
    }

    func testSiteIntentNotAvailableWhenFeatureFlagOff() throws {

        // Given
        let featureFlags = FeatureFlagOverrideStore()
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: false)
        let mockVariant = SiteIntentABMock(override: .treatment)
        let mockSiteCreator = SiteCreator()

        // When
        let siteIntentStep = SiteIntentStep(siteIntentAB: mockVariant, creator: mockSiteCreator)

        // Then
        XCTAssertNil(siteIntentStep)
    }

    func testSiteIntentAvailableForTreatmentGroup() throws {

        // Given
        let featureFlags = FeatureFlagOverrideStore()
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        let mockVariant = SiteIntentABMock(override: .treatment)
        let mockSiteCreator = SiteCreator()

        // When
        let siteIntentStep = SiteIntentStep(siteIntentAB: mockVariant, creator: mockSiteCreator)

        // Then
        XCTAssertNotNil(siteIntentStep)
    }

    func testSiteIntentNotAvailableForControlGroup() throws {

        // Given
        let featureFlags = FeatureFlagOverrideStore()
        try featureFlags.override(FeatureFlag.siteIntentQuestion, withValue: true)
        let mockVariant = SiteIntentABMock(override: .control)
        let mockSiteCreator = SiteCreator()

        // When
        let siteIntentStep = SiteIntentStep(siteIntentAB: mockVariant, creator: mockSiteCreator)

        // Then
        XCTAssertNil(siteIntentStep)
    }
}
