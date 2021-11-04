import Foundation
@testable import WordPress

fileprivate extension UnifiedAboutTracker.ButtonPressedEvent.Button {
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

class UnifiedAboutTrackerTests: XCTestCase {
    func testTrackingScreenShown() {
        let tracker = UnifiedAboutTracker() { (eventName, properties) in
            XCTAssertEqual(eventName, "about_screen_shown")
            XCTAssert(properties.isEmpty)
        }

        tracker.track(UnifiedAboutTracker.ScreenShownEvent())
    }

    func testTrackingScreenDismissed() {
        let tracker = UnifiedAboutTracker() { (eventName, properties) in
            XCTAssertEqual(eventName, "about_screen_dismissed")
            XCTAssert(properties.isEmpty)
        }

        tracker.track(UnifiedAboutTracker.ScreenDismissedEvent())
    }

    func testTrackingButtonPressed() {
        for button in UnifiedAboutTracker.ButtonPressedEvent.Button.allCases {
            let tracker = UnifiedAboutTracker() { (eventName, properties) in
                XCTAssertEqual(eventName, "about_screen_button_tapped")
                XCTAssertEqual(properties, ["button": button.expectedButtonName()])
            }

            tracker.track(UnifiedAboutTracker.ButtonPressedEvent(button: button))
        }
    }
}
