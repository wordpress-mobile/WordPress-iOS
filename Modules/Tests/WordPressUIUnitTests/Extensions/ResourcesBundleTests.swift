import XCTest

import WordPressUI

class ResourcesBundleTests: XCTestCase {

    func testResourceBundleImageCanBeLoaded() {
        let icon = UIImage(named: "icon-url-field", in: Bundle.wordPressUIBundle, compatibleWith: nil)
        XCTAssertNotNil(icon)
    }

    func testFancyAlertStoryboardCanBeLoaded() {
        let storyboard = UIStoryboard(name: "FancyAlerts", bundle: .wordPressUIBundle)
        XCTAssertNotNil(storyboard.instantiateInitialViewController())
    }

}
