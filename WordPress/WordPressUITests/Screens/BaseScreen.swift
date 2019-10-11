import Foundation
import XCTest

class BaseScreen {
    enum UITestError: Error {
        case unableToLocateElement
    }

    var app: XCUIApplication!
    var expectedElement: XCUIElement!
    var waitTimeout: Double!

    init(element: XCUIElement) {
        app = XCUIApplication()
        expectedElement = element
        waitTimeout = 20
        try! waitForPage()
    }

    @discardableResult
    func waitForPage() throws -> BaseScreen {
        XCTContext.runActivity(named: "Confirm page \(self) is loaded") { (activity) in
            let result = waitFor(element: expectedElement, predicate: "isEnabled == true", timeout: 20)
            XCTAssert(result, "Page \(self) is not loaded.")
            Logger.log(message: "Page \(self) is loaded", event: .i)
        }
        return self
    }

    @discardableResult
    func waitFor(element: XCUIElement, predicate: String, timeout: Int? = nil) -> Bool {
        let timeoutValue = timeout ?? 5

        let elementPredicate = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate), object: element)
        let result = XCTWaiter.wait(for: [elementPredicate], timeout: TimeInterval(timeoutValue))

        return result == .completed
    }

    func isLoaded() -> Bool {
        return expectedElement.exists
    }

    class func waitForLoadingIndicatorToDisappear(within timeout: TimeInterval) {
        let networkLoadingIndicator = XCUIApplication().otherElements.deviceStatusBars.networkLoadingIndicators.element
        let networkLoadingIndicatorDisappeared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: networkLoadingIndicator)
        _ = XCTWaiter.wait(for: [networkLoadingIndicatorDisappeared], timeout: timeout)
    }

    func openMagicLink() {
        XCTContext.runActivity(named: "Open magic link in Safari") { (activity) in
            let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
            safari.launch()

            // Select the URL bar when Safari opens
            let urlBar = safari.textFields["URL"]
            waitFor(element: urlBar, predicate: "exists == true")
            if !urlBar.exists {
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
}

private extension XCUIElementAttributes {
    var isNetworkLoadingIndicator: Bool {
        if hasWhiteListedIdentifier { return false }

        let hasOldLoadingIndicatorSize = frame.size == CGSize(width: 10, height: 20)
        let hasNewLoadingIndicatorSize = frame.size.width.isBetween(46, and: 47) && frame.size.height.isBetween(2, and: 3)

        return hasOldLoadingIndicatorSize || hasNewLoadingIndicatorSize
    }

    var hasWhiteListedIdentifier: Bool {
        let whiteListedIdentifiers = ["GeofenceLocationTrackingOn", "StandardLocationTrackingOn"]

        return whiteListedIdentifiers.contains(identifier)
    }

    func isStatusBar(_ deviceWidth: CGFloat) -> Bool {
        if elementType == .statusBar { return true }
        guard frame.origin == .zero else { return false }

        let oldStatusBarSize = CGSize(width: deviceWidth, height: 20)
        let newStatusBarSize = CGSize(width: deviceWidth, height: 44)

        return [oldStatusBarSize, newStatusBarSize].contains(frame.size)
    }
}

private extension XCUIElementQuery {
    var networkLoadingIndicators: XCUIElementQuery {
        let isNetworkLoadingIndicator = NSPredicate { (evaluatedObject, _) in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }

            return element.isNetworkLoadingIndicator
        }

        return self.containing(isNetworkLoadingIndicator)
    }

    var deviceStatusBars: XCUIElementQuery {
        let deviceWidth = XCUIApplication().frame.width

        let isStatusBar = NSPredicate { (evaluatedObject, _) in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }

            return element.isStatusBar(deviceWidth)
        }

        return self.containing(isStatusBar)
    }
}

private extension CGFloat {
    func isBetween(_ numberA: CGFloat, and numberB: CGFloat) -> Bool {
        return numberA...numberB ~= self
    }
}
