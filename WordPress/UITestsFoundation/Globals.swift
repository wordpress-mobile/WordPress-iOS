import UIKit
import XCTest
import ScreenObject

// TODO: This should maybe go in an `XCUIApplication` extension? Also, should it be computed rather
// than stored as a reference? 🤔
public let navBackButton = XCUIApplication().navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)

extension ScreenObject {

    // TODO: This was implemented on the original `BaseScreen` and is here just as a copy-paste for the transition.
    /// Pops the navigation stack, returning to the item above the current one.
    public func pop() {
        navBackButton.tap()
    }

    public func openMagicLink() {
        XCTContext.runActivity(named: "Open magic link in Safari") { activity in
            let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
            safari.launch()

            // Select the URL bar when Safari opens
            let urlBar = safari.textFields["URL"]
            if !urlBar.waitForExistence(timeout: 5) {
                safari.buttons["URL"].tap()
            }

            // Follow the magic link
            var magicLinkComponents = URLComponents(url: WireMock.URL(), resolvingAgainstBaseURL: false)!
            magicLinkComponents.path = "/magic-link"
            magicLinkComponents.queryItems = [URLQueryItem(name: "scheme", value: "wpdebug")]

            urlBar.typeText("\(magicLinkComponents.url!.absoluteString)\n")

            // Accept the prompt to open the deep link
            safari.scrollViews.element(boundBy: 0).buttons.element(boundBy: 1).tap()
        }
    }

    @discardableResult
    public func dismissNotificationAlertIfNeeded(
        _ action: FancyAlertComponent.Action = .cancel
    ) throws -> Self {
        guard FancyAlertComponent.isLoaded() else { return self }

        switch action {
        case .accept:
            try FancyAlertComponent().acceptAlert()
        case .cancel:
            try FancyAlertComponent().cancelAlert()
        }

        return self
    }
}
