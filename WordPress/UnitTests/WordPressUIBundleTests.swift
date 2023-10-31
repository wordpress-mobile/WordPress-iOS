import XCTest
import WordPressUI

/// This tests are intended to ensure that WordPressUI resources are loaded correctly in the app.
/// It should prevent a regression of issues like https://github.com/wordpress-mobile/WordPress-iOS/issues/11848
class WordPressUIBundleTests: XCTestCase {

    func testImageLoading() {
        let gravatarImage = UIImage.gravatarPlaceholderImage
        XCTAssertNotNil(gravatarImage)
    }

    func testFancyAlertsLoading() {
        let config = FancyAlertViewController.Config(titleText: "Title",
                                                     bodyText: "Body",
                                                     headerImage: UIImage.gravatarPlaceholderImage,
                                                     dividerPosition: .bottom,
                                                     defaultButton: nil,
                                                     cancelButton: nil,
                                                     neverButton: nil,
                                                     moreInfoButton: nil,
                                                     titleAccessoryButton: nil,
                                                     switchConfig: nil,
                                                     appearAction: nil,
                                                     dismissAction: nil)
        let vc = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        XCTAssertNotNil(vc)
    }

}
