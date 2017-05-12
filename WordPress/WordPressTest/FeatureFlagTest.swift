import Nimble
import XCTest
@testable import WordPress

class FeatureFlagTest: XCTestCase {

    func testBuild() {
        Build.withCurrent(.debug) {
            expect(build(.debug)).to(beTrue())
            expect(build(.debug, .buddy)).to(beTrue())
            expect(build(.buddy)).to(beFalse())
            expect(build(.internal)).to(beFalse())
            expect(build(.appStore)).to(beFalse())
        }

        Build.withCurrent(.appStore) {
            expect(build(.debug)).to(beFalse())
            expect(build(.buddy)).to(beFalse())
            expect(build(.internal)).to(beFalse())
            expect(build(.appStore)).to(beTrue())
            expect(build(.internal,.appStore)).to(beTrue())
        }
    }

    // Add tests for features that should be disabled in production here.
    func testEnsureDisabledFeaturesInProduction() {
        Build.withCurrent(.appStore) {
//            Example:
//            expect(FeatureFlag.[FeatureEnum].enabled).to(beFalse())
        }
    }
}

extension Build {
    static func withCurrent(_ value: Build, block: () -> Void) {
        Build._overrideCurrent = value
        block()
        Build._overrideCurrent = nil
    }
}
