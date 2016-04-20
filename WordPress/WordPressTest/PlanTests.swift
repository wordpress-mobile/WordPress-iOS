import XCTest
import Nimble
@testable import WordPress

class PlanTests: XCTestCase {
    func testPlanImageName() {
        expect(defaultPlans[0].imageName).to(equal("plan-free"))
        expect(defaultPlans[1].imageName).to(equal("plan-premium"))
        expect(defaultPlans[2].imageName).to(equal("plan-business"))

        expect(defaultPlans[0].activeImageName).to(equal("plan-free-active"))
        expect(defaultPlans[1].activeImageName).to(equal("plan-premium-active"))
        expect(defaultPlans[2].activeImageName).to(equal("plan-business-active"))
    }

    /// Since we're force unwrapping the UIImage creation, let's check the images
    /// to prevent crashing in the app
    func testPlanImage() {
        expect(defaultPlans[0].image).toNot(beNil())
        expect(defaultPlans[1].image).toNot(beNil())
        expect(defaultPlans[2].image).toNot(beNil())

        expect(defaultPlans[0].activeImage).toNot(beNil())
        expect(defaultPlans[1].activeImage).toNot(beNil())
        expect(defaultPlans[2].activeImage).toNot(beNil())
    }
}
