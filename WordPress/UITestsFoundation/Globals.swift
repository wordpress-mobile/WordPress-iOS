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

public func waitForExistAndTap(_ element: XCUIElement, timeout: TimeInterval = 5) {
    guard element.waitForExistence(timeout: timeout) else {
        XCTFail("Expected element (\(element)) did not exist after \(timeout) seconds.")
        return
    }

    element.tap()
}

public func waitAndTap( _ element: XCUIElement, maxRetries: Int = 10, timeout: TimeInterval = 10) {
    guard element.waitForIsHittable(timeout: timeout) else {
        XCTFail("Expected element (\(element)) was not hittable after \(timeout) seconds.")
        return
    }

    var retries = 0
    while retries < maxRetries {
        if element.isHittable {
            element.tap()
            break
        }
        retries += 1
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
            let safari = Apps.safari
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

    public func findSafariAddressBar(hasBeenTapped: Bool) -> XCUIElement {
        let safari = Apps.safari

        // when the device is iPad and addressBar has not been tapped the element is a button
        if UIDevice.current.userInterfaceIdiom == .pad && !hasBeenTapped {
            return safari.buttons["Address"]
        }

        return safari.textFields["Address"]
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

    @discardableResult
    public func assertScreenIsLoaded(file: StaticString = #file, line: UInt = #line) -> Self {
        XCTAssertTrue(isLoaded, file: file, line: line)
        return self
    }
}

public enum Apps {

    public static let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
    public static let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
}
