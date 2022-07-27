import XCTest

// TODO: This might be better suited in the XCUITestHelpers frameworks.
public extension XCUIElementQuery {

    var lastMatch: XCUIElement? {
        return self.allElementsBoundByIndex.last
    }
}
