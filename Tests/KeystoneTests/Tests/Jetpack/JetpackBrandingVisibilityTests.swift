@testable import WordPress
import XCTest

class JetpackBrandingVisibilityTests: XCTestCase {

    func testEnabledCaseAll() {
        let visibility = JetpackBrandingVisibility.all

        for isStaticScreensWithReader in [true, false] {
            TruthTable.threeValues.forEach {
                let isEnabled = visibility.isEnabled(
                    isWordPress: $0,
                    isDotComAvailable: $1,
                    shouldShowJetpackFeatures: $2,
                    isStaticScreensWithReader: isStaticScreensWithReader
                )

                // Only visible if:
                // - the app is WordPress,
                // - there is a DotCom account,
                // - shouldShowJetpackFeatures is true,
                // - the app UI type isn't `staticScreensWithReader`
                let expected = $0 && $1 && $2 && !isStaticScreensWithReader
                XCTAssertEqual(
                    isEnabled,
                    expected,
                    "isEnabled for WordPress \($0), DotCom \($1), Jetpack features \($2), and static screens with Reader \(isStaticScreensWithReader) was not \(expected)"
                )
            }
        }
    }
}
