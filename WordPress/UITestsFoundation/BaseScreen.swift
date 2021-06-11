import XCTest

// Access control `open` so types outside of this framework can subclass it, which is exactly how
// this type is meant to be used.
open class BaseScreen {

    public private(set) var app: XCUIApplication!
    public private(set) var expectedElement: XCUIElement!
    var waitTimeout: Double!

    public init(element: XCUIElement) {
        app = XCUIApplication()
        expectedElement = element
        waitTimeout = 20
        try! waitForPage()
    }

    @discardableResult
    public func waitForPage() throws -> BaseScreen {
        XCTContext.runActivity(named: "Confirm page \(self) is loaded") { (activity) in
            let result = waitFor(element: expectedElement, predicate: "isEnabled == true", timeout: 20)
            XCTAssert(result, "Page \(self) is not loaded.")
        }
        return self
    }

    @discardableResult
    public func waitFor(element: XCUIElement, predicate: String, timeout: Int? = nil) -> Bool {
        let timeoutValue = timeout ?? 5

        let elementPredicate = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate), object: element)
        let result = XCTWaiter.wait(for: [elementPredicate], timeout: TimeInterval(timeoutValue))

        return result == .completed
    }

    public func isLoaded() -> Bool {
        return expectedElement.exists
    }

    public func tapStatusBarToScrollToTop() {
        // A hack to work around there being no status bar – just tap the appropriate spot on the navigation bar
        XCUIApplication().navigationBars.allElementsBoundByIndex.forEach {
           $0.coordinate(withNormalizedOffset: CGVector(dx: 20, dy: -20)).tap()
        }
    }
}

// MARK: - Dump of files from the other targets
// All in this one to avoid messing up with the project file during the transition...

import Foundation

extension BaseScreen {

    func openMagicLink() {
        XCTContext.runActivity(named: "Open magic link in Safari") { (activity) in
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
}

class WireMock {
    private static let hostInfoPlistKey = "WIREMOCK_HOST"
    private static let portInfoPlistKey = "WIREMOCK_PORT"

    static func URL() -> Foundation.URL {
        let host = infoPlistEntry(key: hostInfoPlistKey)
        let port = infoPlistEntry(key: portInfoPlistKey)
        return Foundation.URL(string: "http://\(host):\(port)/")!
    }

    private static func infoPlistEntry(key: String) -> String {
        let plistUrl = Bundle(for: WireMock.self).url(forResource: "Info", withExtension: "plist")!
        return NSDictionary(contentsOf: plistUrl)![key] as! String
    }
}

// TODO: This might be better suited in the XCUITestHelpers frameworks.
public extension XCUIElementQuery {

    var allElementsShareCommonXAxis: Bool {
        let elementXPositions = allElementsBoundByIndex.map { $0.frame.minX }

        // Use a set to remove duplicates – if all elements are the same, only one should remain
        return Set(elementXPositions).count == 1
    }
}

// TODO: This should go into a UIDevice extension (eg: `UIDevice.current.isPad`)
public var isIpad: Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}
// TODO: This should go into a UIDevice extension (eg: `UIDevice.current.isPhone`)
var isIPhone: Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
}

// TODO: This should maybe go in an `XCUIApplication` extension? Also, should it be computed rather
// than stored as a reference? 🤔
let navBackButton = XCUIApplication().navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)

// TODO: This should go XCUITestHelpers if not there already
public extension XCUIElement {

    /**
     Pastes text from clipboard to the field
     Useful for scenarios where typing is problematic, e.g. secure text fields in Russian.
     - Parameter text: the text to paste into the field
     */
    func pasteText(_ text: String) -> Void {
        let previousPasteboardContents = UIPasteboard.general.string
        UIPasteboard.general.string = text

        press(forDuration: 1.2)
        XCUIApplication().menuItems.firstMatch.tap()

        if let string = previousPasteboardContents {
            UIPasteboard.general.string = string
        }
    }

    @discardableResult
    // TODO: When moving to framework, find name that doesn't trigger grammar warning
    func waitForHittability(timeout: TimeInterval) -> Bool {

        let predicate = NSPredicate(format: "isHittable == true")
        let elementPredicate = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [elementPredicate], timeout: timeout)

        return result == .completed
    }
}
