import Nimble
import XCTest
@testable import WordPress

class BuildTests: XCTestCase {

    func testBuild() {
        Build.withCurrent(.localDeveloper) {
            expect(Build.is(.localDeveloper)).to(beTrue())
            expect(Build.is([.localDeveloper, .a8cBranchTest])).to(beTrue())
            expect(Build.is(.a8cBranchTest)).to(beFalse())
            expect(Build.is(.a8cPrereleaseTesting)).to(beFalse())
            expect(Build.is(.appStore)).to(beFalse())
        }

        Build.withCurrent(.appStore) {
            expect(Build.is(.localDeveloper)).to(beFalse())
            expect(Build.is(.a8cBranchTest)).to(beFalse())
            expect(Build.is(.a8cPrereleaseTesting)).to(beFalse())
            expect(Build.is(.appStore)).to(beTrue())
            expect(Build.is([.a8cPrereleaseTesting, .appStore])).to(beTrue())
        }
    }
}
