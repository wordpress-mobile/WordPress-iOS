import UIKit
import XCTest

// TODO: This should go into a UIDevice extension (eg: `UIDevice.current.isPad`)
public var isIpad: Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}
// TODO: This should go into a UIDevice extension (eg: `UIDevice.current.isPhone`)
public var isIPhone: Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
}

// TODO: This should maybe go in an `XCUIApplication` extension? Also, should it be computed rather
// than stored as a reference? 🤔
public let navBackButton = XCUIApplication().navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)
