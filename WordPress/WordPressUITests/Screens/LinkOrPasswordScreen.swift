//
//  LinkOrPasswordScreen.swift
//  WordPressUITests
//
//  Created by brbrr on 12/5/17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import Foundation
import XCTest

class LinkOrPasswordScreen: BaseScreen {
    let passwordOption: XCUIElement

    init() {
        passwordOption = XCUIApplication().buttons["Use Password"]
        super.init(element: passwordOption)
    }

    func proceedWithPassword() -> LoginPasswordScreen {
        passwordOption.tap()

        return LoginPasswordScreen.init()
    }
}
