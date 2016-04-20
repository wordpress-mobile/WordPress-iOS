import XCTest
import Nimble
@testable import WordPress

class PlanDetailViewControllerTest: XCTestCase {
    
    // MARK: - FeatureListItemRow tests
    
    func testFeatureListItemRowAvailableFeature() {
        let feature = PlanFeature.NoAds
        let row = FeatureListItemRow(feature: feature, available: true)
        
        expect(row.text).notTo(beEmpty())
        expect(row.detailText).to(beNil())
        expect(row.availableIndicator).to(beTrue())
    }
    
    func testFeatureListItemRowAvailableFeatureWebOnly() {
        let feature = PlanFeature.CustomDomain
        let row = FeatureListItemRow(feature: feature, available: true)
        
        expect(row.text).notTo(beEmpty())
        expect(row.detailText).to(contain("WEB ONLY"))
        expect(row.availableIndicator).to(beTrue())
    }
    
    func testFeatureListItemRowUnavailableFeature() {
        let feature = PlanFeature.NoAds
        let row = FeatureListItemRow(feature: feature, available: false)
        
        expect(row.text).notTo(beEmpty())
        expect(row.detailText).to(beNil())
        expect(row.availableIndicator).to(beFalse())
    }
    
    func testFeatureListItemRowUnavailableFeatureWebOnly() {
        let feature = PlanFeature.CustomDomain
        let row = FeatureListItemRow(feature: feature, available: false)
        
        expect(row.text).notTo(beEmpty())
        // Don't show any detail text for unavailable items
        expect(row.detailText).to(beNil())
        expect(row.availableIndicator).to(beFalse())
    }
}
