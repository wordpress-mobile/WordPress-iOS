import XCTest

/// A menu or popover of buttons, opened from another button.
final class MenuComponent: ScreenObject {
    /// - Parameter item: The title of an item the menu is known to contain, which identifies it.
    init(expecting item: String, app: XCUIApplication) throws {
        try super.init(expectedElementGetters: [{ $0.buttons[item] }], app: app)
    }

    func item(_ title: String) -> XCUIElement {
        app.buttons[title]
    }

    /// The item whose title starts with `prefix`. Some items append their current value to their
    /// title, such as "Compare With…, Preceding Period".
    func item(beginningWith prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    /// Waits for the menu to show every one of `titles`.
    @discardableResult
    func waitForItems(_ titles: [String]) throws -> Self {
        for title in titles {
            try waitFor(item(title))
        }
        return self
    }

    /// Taps an item. Returns the menu, because an item that opens a submenu shows more items.
    @discardableResult
    func select(_ title: String) throws -> Self {
        try tap(item(title))
        return self
    }

    @discardableResult
    func select(beginningWith prefix: String) throws -> Self {
        try tap(item(beginningWith: prefix))
        return self
    }
}
