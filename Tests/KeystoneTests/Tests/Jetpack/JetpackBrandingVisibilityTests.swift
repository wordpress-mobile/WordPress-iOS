@testable import WordPress
import XCTest

class JetpackBrandingVisibilityTests: XCTestCase {

    func testEnabledCaseAll() {
        let visibility = JetpackBrandingVisibility.all

        for isReaderTabsUI in [true, false] {
            TruthTable.threeValues.forEach {
                let isEnabled = visibility.isEnabled(
                    isWordPress: $0,
                    isDotComAvailable: $1,
                    shouldShowJetpackFeatures: $2,
                    isReaderTabsUI: isReaderTabsUI
                )

                // Only visible if:
                // - the app is WordPress,
                // - there is a DotCom account,
                // - shouldShowJetpackFeatures is true,
                // - the app doesn't show the Reader-tabs UI
                let expected = $0 && $1 && $2 && !isReaderTabsUI
                XCTAssertEqual(
                    isEnabled,
                    expected,
                    "isEnabled for WordPress \($0), DotCom \($1), Jetpack features \($2), and Reader tabs \(isReaderTabsUI) was not \(expected)"
                )
            }
        }
    }
}
