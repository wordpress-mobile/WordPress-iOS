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

    /// Scroll an element into view within another element.
    /// scrollView can be a UIScrollView, or anything that subclasses it like UITableView
    ///
    /// TODO: The implementation of this could use work:
    /// - What happens if the element is above the current scroll view position?
    /// - What happens if it's a really long scroll view?
    //
    // FIXME: This is already part of XCUITestHelpers
    public func scrollElementIntoView(element: XCUIElement, within scrollView: XCUIElement, threshold: Int = 1000) {

        var iteration = 0

        while !element.isFullyVisibleOnScreen && iteration < threshold {
            scrollView.scroll(byDeltaX: 0, deltaY: 100)
            iteration += 1
        }

        if !element.isFullyVisibleOnScreen {
            XCTFail("Unable to scroll element into view")
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

    // This was `private` in the file it came from. We need `fileprivate` in this configuration in
    // this particular file. It's likely we can changed the access control, but I want to keep
    // things as similar as the previous setup while moving files around.
    fileprivate var isFullyVisibleOnScreen: Bool {
        guard self.exists && !self.frame.isEmpty && self.isHittable else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(self.frame)
    }

    func scroll(byDeltaX deltaX: CGFloat, deltaY: CGFloat) {
        let startCoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let destination = startCoordinate.withOffset(CGVector(dx: deltaX, dy: deltaY * -1))

        startCoordinate.press(forDuration: 0.01, thenDragTo: destination)
    }
}

// MARK: - Logger

enum LogEvent: String {
    case e = "[‼️]" // error
    case i = "[ℹ️]" // info
    case d = "[💬]" // debug
    case v = "[🔬]" // verbose
    case w = "[⚠️]" // warning
    case s = "[🔥]" // severe
}

// Usage examples:
//  Logger.log(message: "blogsPage.isLoaded()): \(blogsPage.isLoaded()))", event: .d)
//  Logger.log(message: "Hey ho, lets go!", event: .v)
// Output example:
//  2017-11-23 03:16:32025 [ℹ️][BasePage.swift]:18 19 waitForPage() -> Page AztecUITests.BlogsPage is loaded
class Logger {
    // 1. The date formatter
    static var dateFormat = "yyyy-MM-dd hh:mm:ssSSS" // Use your own
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }

    private class func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }

    class func log(message: String, event: LogEvent,
                   fileName: String = #file, line: Int = #line,
                   column: Int = #column, funcName: String = #function) {
        #if DEBUG // 7.
            print("\(Date().toString()) \(event.rawValue)[\(sourceFileName(filePath: fileName))]:\(line) \(funcName) -> \(message)")
        #endif // 7.
    }
}


// 2. The Date to String extension
extension Date {
    func toString() -> String {
        return Logger.dateFormatter.string(from: self as Date)
    }
}
// MARK: -
