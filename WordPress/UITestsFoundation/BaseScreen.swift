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
