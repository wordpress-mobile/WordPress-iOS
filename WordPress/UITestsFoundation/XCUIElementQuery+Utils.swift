import XCTest

// TODO: This might be better suited in the XCUITestHelpers frameworks.
public extension XCUIElementQuery {

    var allElementsShareCommonXAxis: Bool {
        let elementXPositions = allElementsBoundByIndex.map { $0.frame.minX }

        // Use a set to remove duplicates – if all elements are the same, only one should remain
        return Set(elementXPositions).count == 1
    }

    var lastMatch: XCUIElement? {
        return self.allElementsBoundByIndex.last
    }
}
