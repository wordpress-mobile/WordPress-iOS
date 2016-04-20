import Nimble
import XCTest
@testable import WordPress

class FeatureFlagTest: XCTestCase {

    func testBuild() {
        Build.withCurrent(.Debug) {
            expect(build(.Debug)).to(beTrue())
            expect(build(.Debug, .Alpha)).to(beTrue())
            expect(build(.Alpha)).to(beFalse())
            expect(build(.Internal)).to(beFalse())
            expect(build(.AppStore)).to(beFalse())
        }

        Build.withCurrent(.AppStore) {
            expect(build(.Debug)).to(beFalse())
            expect(build(.Alpha)).to(beFalse())
            expect(build(.Internal)).to(beFalse())
            expect(build(.AppStore)).to(beTrue())
            expect(build(.Internal,.AppStore)).to(beTrue())
        }
    }

    func testEnsureDisabledFeaturesInProduction() {
        Build.withCurrent(.AppStore) {
            expect(FeatureFlag.People.enabled).to(beFalse())
            expect(FeatureFlag.Plans.enabled).to(beFalse())
        }
    }

}

extension Build {
    static func withCurrent(value: Build, @noescape block: () -> Void) {
        Build._overrideCurrent = value
        block()
        Build._overrideCurrent = nil
    }
}
