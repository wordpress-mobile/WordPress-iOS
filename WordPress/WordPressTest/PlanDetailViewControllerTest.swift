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
    
    func testFeatureListItemRowAvailableFeatureWithDetail() {
        let feature = PlanFeature.StorageSpace("10GB")
        let row = FeatureListItemRow(feature: feature, available: true)

        expect(row.text).notTo(beEmpty())
        expect(row.detailText).to(contain("10GB"))
        expect(row.availableIndicator).to(beNil())
    }
    
    func testFeatureListItemRowAvailableFeatureWebOnlyNoDetail() {
        let feature = PlanFeature.CustomDomain
        let row = FeatureListItemRow(feature: feature, available: true)
        
        expect(row.text).notTo(beEmpty())
        expect(row.detailText).to(contain("WEB ONLY"))
        expect(row.availableIndicator).to(beTrue())
    }
    
    func testFeatureListItemRowUnavailableFeatureNoDetail() {
        let feature = PlanFeature.NoAds
        let row = FeatureListItemRow(feature: feature, available: false)
        
        expect(row.text).notTo(beEmpty())
        expect(row.detailText).to(beNil())
        expect(row.availableIndicator).to(beFalse())
    }
    
    func testFeatureListItemRowUnavailableFeatureWithDetail() {
        let feature = PlanFeature.StorageSpace("10GB")
        let row = FeatureListItemRow(feature: feature, available: false)
        
        expect(row.text).notTo(beEmpty())
        expect(row.detailText).to(equal("10GB"))
        expect(row.availableIndicator).to(beNil())
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
