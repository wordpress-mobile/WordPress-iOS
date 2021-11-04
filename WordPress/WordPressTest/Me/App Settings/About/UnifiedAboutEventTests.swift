import Foundation
@testable import WordPress

fileprivate extension UnifiedAboutEvent.Button {
    /// This method is useful to prevent the button names from being changed by mistake in our sources.
    /// It's also useful because if cases are added or removed, the tests wont build until they're added here,
    /// which helps us guarantee 100% testing coverage for this type of event.
    ///
    func expectedButtonName() -> String {
        switch self {
        case .dismiss:
            return "dismiss"
        case .rateUs:
            return "rate_us"
        case .share:
            return "share"
        case .twitter:
            return "twitter"
        case .legal:
            return "legal"
        case .automatticFamily:
            return "automattic_family"
        case .workWithUs:
            return "work_with_us"
        case .appDayone:
            return "app_dayone"
        case .appJetpack:
            return "app_jetpack"
        case .appPocketcasts:
            return "app_pocketcasts"
        case .appSimplenote:
            return "app_simplenote"
        case .appWoo:
            return "app_woo"
        case .appTumblr:
            return "app_tumblr"
        case .appWordpress:
            return "app_wordpress"
        }
    }
}

class UnifiedAboutEventTests: XCTestCase {
    func testTrackingScreenShown() {
        let event: UnifiedAboutEvent = .screenShown

        XCTAssertEqual(event.name, "about_screen_shown")
        XCTAssert(event.properties.isEmpty)
    }

    func testTrackingScreenDismissed() {
        let event: UnifiedAboutEvent = .screenDismissed

        XCTAssertEqual(event.name, "about_screen_dismissed")
        XCTAssert(event.properties.isEmpty)
    }

    func testTrackingButtonPressed() {
        for button in UnifiedAboutEvent.Button.allCases {
            let event: UnifiedAboutEvent = .buttonPressed(button: button)

            XCTAssertEqual(event.name, "about_screen_button_tapped")
            XCTAssertEqual(event.properties, ["button": button.expectedButtonName()])
        }
    }
}
