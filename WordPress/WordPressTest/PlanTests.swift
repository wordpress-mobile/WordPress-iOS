import XCTest
import Nimble
@testable import WordPress

class PlanTests: XCTestCase {
    func testPlanImageName() {
        expect(Plan.Free.imageName).to(equal("plan-free"))
        expect(Plan.Premium.imageName).to(equal("plan-premium"))
        expect(Plan.Business.imageName).to(equal("plan-business"))

        expect(Plan.Free.activeImageName).to(equal("plan-free-active"))
        expect(Plan.Premium.activeImageName).to(equal("plan-premium-active"))
        expect(Plan.Business.activeImageName).to(equal("plan-business-active"))
    }

    /// Since we're force unwrapping the UIImage creation, let's check the images
    /// to prevent crashing in the app
    func testPlanImage() {
        expect(Plan.Free.image).toNot(beNil())
        expect(Plan.Premium.image).toNot(beNil())
        expect(Plan.Business.image).toNot(beNil())

        expect(Plan.Free.activeImage).toNot(beNil())
        expect(Plan.Premium.activeImage).toNot(beNil())
        expect(Plan.Business.activeImage).toNot(beNil())
    }
}
