import XCTest
import Nimble
@testable import WordPress

public func containAnInstanceOf(expectedClass: AnyClass) -> NonNilMatcherFunc<Array<NSObject>> {
    return NonNilMatcherFunc { actualExpression, failureMessage in
        failureMessage.postfixMessage = "contain an instance of <\(expectedClass)>"
        guard let actual = try actualExpression.evaluate() else { return false }
        
        for item in actual {
            if item.isMemberOfClass(expectedClass) {
                return true
            }
        }
        
        return false
    }
}

class PlanDetailViewControllerTest: XCTestCase {
    
    // MARK: - FeatureListItemRow tests
    
    func testFeatureListItemRowAvailableFeature() {
        let feature = PlanFeature.NoAds
        let row = FeatureListItemRow(feature: feature, available: true)
        
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
        row.configureCell(cell)
        
        expect(cell.textLabel?.text).notTo(beEmpty())
        expect(cell.detailTextLabel?.text).to(beNil())
        // The accessory view should be an imageview (checkmark)
        expect(cell.accessoryView?.subviews).to(containAnInstanceOf(UIImageView))
    }
    
    func testFeatureListItemRowAvailableFeatureWithDetail() {
        let feature = PlanFeature.StorageSpace("10GB")
        let row = FeatureListItemRow(feature: feature, available: true)
        
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
        row.configureCell(cell)
        
        expect(cell.textLabel?.text).notTo(beEmpty())
        expect(cell.detailTextLabel?.text).to(contain("10GB"))
        expect(cell.accessoryView).to(beNil())
    }
    
    func testFeatureListItemRowAvailableFeatureWebOnlyNoDetail() {
        let feature = PlanFeature.CustomDomain
        let row = FeatureListItemRow(feature: feature, available: true)
        
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
        row.configureCell(cell)
        
        expect(cell.textLabel?.text).notTo(beEmpty())
        expect(cell.detailTextLabel?.text).to(contain("WEB ONLY"))
        expect(cell.accessoryView?.subviews).to(containAnInstanceOf(UIImageView))
    }
    
    func testFeatureListItemRowUnavailableFeatureNoDetail() {
        let feature = PlanFeature.NoAds
        let row = FeatureListItemRow(feature: feature, available: false)
        
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
        row.configureCell(cell)
        
        expect(cell.textLabel?.text).notTo(beEmpty())
        expect(cell.detailTextLabel?.text).to(beNil())
        expect(cell.accessoryView?.subviews).notTo(containAnInstanceOf(UIImageView))
    }
    
    func testFeatureListItemRowUnavailableFeatureWithDetail() {
        let feature = PlanFeature.StorageSpace("10GB")
        let row = FeatureListItemRow(feature: feature, available: false)
        
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
        row.configureCell(cell)
        
        expect(cell.textLabel?.text).notTo(beEmpty())
        expect(cell.detailTextLabel?.text).to(beNil())
        // Don't show any detail text for unavailable items
        expect(cell.accessoryView?.subviews).notTo(containAnInstanceOf(UIImageView))
    }
    
    func testFeatureListItemRowUnavailableFeatureWebOnly() {
        let feature = PlanFeature.CustomDomain
        let row = FeatureListItemRow(feature: feature, available: false)
        
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
        row.configureCell(cell)
        
        expect(cell.textLabel?.text).notTo(beEmpty())
        // Don't show any detail text for unavailable items
        expect(cell.detailTextLabel?.text).to(beNil())
        expect(cell.accessoryView?.subviews).notTo(containAnInstanceOf(UIImageView))
    }
}
