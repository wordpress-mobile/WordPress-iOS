import UIKit
import XCTest
import ScreenObject

// TODO: This should maybe go in an `XCUIApplication` extension?
public var navBackButton: XCUIElement { XCUIApplication().navigationBars.element(boundBy: 0).buttons.element(boundBy: 0) }

// This list has all the navBarButton labels currently covered by UI tests and must be updated when adding new ones.
public let navBackButtonLabels = ["Post Settings", "Back", "Get Started"]

// Sometimes the Back Button in Navigation Bar is not recognized by XCUITest as an element.
// This method identifies when it happens and uses a swipe back gesture instead of tapping the button.
public func navigateBack() {
    let app = XCUIApplication()
    let isBackButonAvailableInNavigationBar = navBackButtonLabels.contains(navBackButton.label)

    if isBackButonAvailableInNavigationBar {
        navBackButton.tap()
    } else {
        let leftEdge = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
        let center = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))

        leftEdge.press(forDuration: 0.01, thenDragTo: center)
    }
}

public func pullToRefresh(app: XCUIApplication = XCUIApplication()) {
    let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
    let bottom = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))

    top.press(forDuration: 0.01, thenDragTo: bottom)
}

public func waitAndTap( _ element: XCUIElement) {
    var retries = 0
    let maxRetries = 10
    if element.waitForIsHittable(timeout: 10) {
        while element.isHittable && retries < maxRetries {
            element.tap()
            retries += 1
        }
    }
}

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
