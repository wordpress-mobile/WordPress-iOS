import UIKit
import XCTest
import ScreenObject

// TODO: This should maybe go in an `XCUIApplication` extension? Also, should it be computed rather
// than stored as a reference? 🤔
public let navBackButton = XCUIApplication().navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)

extension ScreenObject {

    // TODO: This was implemented on the original `BaseScreen` and is here just as a copy-paste for the transition.
    /// Pops the navigation stack, returning to the item above the current one.
    public func pop() {
        navBackButton.tap()
    }
}
