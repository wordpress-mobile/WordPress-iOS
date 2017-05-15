import Nimble
import XCTest
@testable import WordPress

class FeatureFlagTest: XCTestCase {

    func testBuild() {
        Build.withCurrent(.localDeveloper) {
            expect(build(.localDeveloper)).to(beTrue())
            expect(build(.localDeveloper, .a8cBranchTest)).to(beTrue())
            expect(build(.a8cBranchTest)).to(beFalse())
            expect(build(.a8cPrereleaseTesting)).to(beFalse())
            expect(build(.appStore)).to(beFalse())
        }

        Build.withCurrent(.appStore) {
            expect(build(.localDeveloper)).to(beFalse())
            expect(build(.a8cBranchTest)).to(beFalse())
            expect(build(.a8cPrereleaseTesting)).to(beFalse())
            expect(build(.appStore)).to(beTrue())
            expect(build(.a8cPrereleaseTesting,.appStore)).to(beTrue())
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
