import XCTest

/// The base class for screen objects (the page object pattern).
///
/// A screen object exposes the elements and actions for one screen, or one component of a screen,
/// so tests read as a chain of user actions instead of element queries. Navigation methods return
/// the screen they navigate to:
///
/// ```swift
/// try MySiteScreen(app: app)
///     .goToCreateSheet()
///     .goToBlogPost()
/// ```
///
/// Initializing a screen waits for its first expected element to become hittable and throws if it
/// doesn't, so constructing a screen object doubles as the assertion that the app reached it.
///
/// Adapted from [Automattic/ScreenObject](https://github.com/Automattic/ScreenObject), which the UI
/// tests removed in #25399 depended on.
@MainActor
class ScreenObject {
    typealias ElementGetter = (XCUIApplication) -> XCUIElement

    struct ScreenNotLoadedError: Error, CustomStringConvertible {
        let screen: String
        let element: String
        let timeout: TimeInterval

        var description: String {
            "\(screen) did not load: \(element) was not hittable after \(timeout) seconds"
        }
    }

    struct ElementNotReachedError: Error, CustomStringConvertible {
        let element: String
        let expectation: String

        var description: String {
            "\(element) \(expectation)"
        }
    }

    static let defaultWaitTimeout: TimeInterval = 20

    /// An element getter for the title shown in the navigation bar.
    static func navigationBarTitle(_ title: String) -> ElementGetter {
        { $0.navigationBars.staticTexts[title] }
    }

    let app: XCUIApplication

    private let expectedElementGetters: [ElementGetter]
    private let waitTimeout: TimeInterval

    /// - Parameters:
    ///   - expectedElementGetters: The elements that identify the screen. The first one is awaited
    ///     at initialization; `waitForScreen()` awaits them all.
    ///   - waitTimeout: How long to wait for each expected element to become hittable.
    init(
        expectedElementGetters: [ElementGetter],
        app: XCUIApplication,
        waitTimeout: TimeInterval = defaultWaitTimeout
    ) throws {
        precondition(!expectedElementGetters.isEmpty, "A screen needs at least one expected element")

        self.app = app
        self.expectedElementGetters = expectedElementGetters
        self.waitTimeout = waitTimeout

        try waitForScreen(firstElementOnly: true)
    }

    /// Waits for the expected elements to become hittable.
    @discardableResult
    func waitForScreen(firstElementOnly: Bool = false) throws -> Self {
        let getters = firstElementOnly ? Array(expectedElementGetters.prefix(1)) : expectedElementGetters

        try XCTContext.runActivity(named: "Wait for \(Self.self)") { _ in
            for getter in getters {
                let element = getter(app)
                guard element.poll(timeout: waitTimeout, until: { $0.exists && $0.isHittable }) else {
                    throw ScreenNotLoadedError(screen: "\(Self.self)", element: "\(element)", timeout: waitTimeout)
                }
            }
        }

        return self
    }

    /// The elements that float over the bottom of the screen's content.
    ///
    /// An element underneath one still reports itself as hittable, so a tap on it lands on the
    /// floating element instead.
    var bottomOverlays: [XCUIElement] { [app.tabBars.firstMatch] }

    /// Scrolls `scrollView` up until `element` can be tapped.
    ///
    /// - Parameter waitsForExistence: Whether to wait for `element` to exist before scrolling.
    ///   Pass `false` for content in a lazy stack, which only exists once it's scrolled to.
    func scroll(
        to element: XCUIElement,
        in scrollView: XCUIElement,
        maxSwipes: Int = 8,
        waitsForExistence: Bool = true
    ) throws {
        if waitsForExistence {
            try waitFor(element)
        }

        var swipes = 0
        while !canTap(element) {
            guard swipes < maxSwipes else {
                let state =
                    element.exists
                    ? "hittable: \(element.isHittable), frame: \(element.frame), "
                        + "overlays: \(bottomOverlays.filter(\.exists).map(\.frame))"
                    : "it doesn't exist"
                throw ElementNotReachedError(
                    element: "\(element)",
                    expectation: "could not be tapped after \(maxSwipes) swipes (\(state))"
                )
            }
            swipeUp(scrollView)
            swipes += 1
        }
    }

    /// Scrolls `scrollView` up by one swipe. A screen overrides this when something in its
    /// content would take the swipe for itself.
    func swipeUp(_ scrollView: XCUIElement) {
        scrollView.swipeUp(velocity: .slow)
    }

    private func canTap(_ element: XCUIElement) -> Bool {
        guard element.exists else {
            return false
        }

        // Asking whether an element that's off screen is hittable can itself fail the test, so
        // rule that out from its frame first.
        let center = CGPoint(x: element.frame.midX, y: element.frame.midY)
        guard !element.frame.isEmpty, app.frame.contains(center) else {
            return false
        }
        guard bottomOverlays.allSatisfy({ !$0.exists || center.y < $0.frame.minY }) else {
            return false
        }
        return element.isHittable
    }

    /// Polls `condition` until it holds.
    ///
    /// - Parameter expectation: What was being waited for, to complete the sentence "<screen>
    ///   did not see…" in the error thrown on timeout.
    func wait(until expectation: String, _ condition: () -> Bool) throws {
        let deadline = Date(timeIntervalSinceNow: waitTimeout)
        while !condition() {
            guard Date() < deadline else {
                throw ElementNotReachedError(element: "\(Self.self)", expectation: "did not see \(expectation)")
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }

    /// Taps the navigation bar's back button.
    func goBack() {
        app.navigationBars.buttons["BackButton"].firstMatch.tap()
    }

    /// Waits for `element` to appear.
    func waitFor(_ element: XCUIElement) throws {
        guard element.pollForExistence(timeout: waitTimeout) else {
            throw ElementNotReachedError(element: "\(element)", expectation: "did not appear")
        }
    }

    /// Taps `element` once it appears.
    func tap(_ element: XCUIElement) throws {
        try waitFor(element)
        element.tap()
    }

    /// Taps the first item of a list once it appears, and skips the test if it never does.
    ///
    /// What a list holds is up to the site the tests are signed in to, and it changes over time:
    /// activity ages out, a quiet week has no referrers. A list with nothing to open isn't a
    /// failure of the app.
    ///
    /// - Parameter name: What the item is, to complete the sentence "This site has no…".
    func tapFirst(_ item: XCUIElement, named name: String) throws {
        guard item.pollForExistence(timeout: waitTimeout) else {
            throw XCTSkip("This site has no \(name) to open")
        }
        item.tap()
    }

    /// The first row of `list` that can be tapped. Section headers and footers are cells too, but
    /// only the rows that navigate somewhere contain a button.
    func firstRow(in list: XCUIElement) -> XCUIElement {
        list.cells.containing(.button, identifier: nil).firstMatch
    }

    /// Taps a filter tab and waits for it to become selected.
    func select(tab: XCUIElement) throws {
        tab.tap()
        try waitForSelection(of: tab)
    }

    /// Waits for a filter tab to be the selected one.
    func waitForSelection(of tab: XCUIElement) throws {
        guard tab.poll(timeout: waitTimeout, until: { $0.exists && $0.isSelected }) else {
            throw ElementNotReachedError(element: "\(tab)", expectation: "was not selected")
        }
    }
}
