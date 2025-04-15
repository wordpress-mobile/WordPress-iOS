@testable import WordPress
import XCTest

class JetpackBrandingVisibilityTests: XCTestCase {

    func testEnabledCaseAll() {
        let visibility = JetpackBrandingVisibility.all

        TruthTable.threeValues.forEach {
            let isEnabled = visibility.isEnabled(
                isWordPress: $0,
                isDotComAvailable: $1,
                shouldShowJetpackFeatures: $2
            )

            // Only visible if:
            // - the app is WordPress,
            // - there is a DotCom account,
            // - shouldShowJetpackFeatures is true
            let expected = $0 && $1 && $2
            XCTAssertEqual(
                isEnabled,
                expected,
                "isEnabled for WordPress \($0), DotCom \($1), and Jetpack features \($2) was not \(expected)"
            )
        }
    }
}
