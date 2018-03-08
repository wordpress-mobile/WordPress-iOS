//
//  WordPressUITestsCostomize.swift
//  WordPressUITestsCostomize
//
//  Created by Xue Qin on 12/14/17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import XCTest

class WordPressUITestsCostomize: TestDataset {
    
    let app = XCUIApplication()
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        if app.buttons["Log In"].exists {
            emailLogin()
        }
        

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /**
     Scrolls to a particular element until it is rendered in the visible rect
     - Parameter elememt: the element we want to scroll to
     */
    func scrollToElement(element: XCUIElement)
    {
        while element.exists == false
        {
            app.swipeUp()
        }
        
        sleep(3)
    }
    
    func emailLogin() {
        // login with email and password
        app.swipeLeft()
        app.swipeLeft()
        app.swipeLeft()
        app.swipeLeft()
        
        app.buttons["Log In"].tap()
        let emailField = app.textFields["Email address"]
        emailField.tap()
        emailField.typeText("xueqin.michelle@gmail.com")
        app.buttons.matching(identifier: "Next").element(boundBy: 0).tap()
        app.buttons["Enter your password instead."].tap()
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("mima8962086")
        app.buttons.matching(identifier: "Next").element(boundBy: 0).tap()
        app.buttons.matching(identifier: "Continue").element(boundBy: 0).tap()
        
        if app.buttons["Not Now"].exists {
            app.buttons.matching(identifier: "Not Now").element(boundBy: 0).tap()
        }
        
    }
    
    func logout() {
        
        app.tabBars["Main Navigation"].buttons["meTabButton"].tap()
        sleep(2)
        app.tables.staticTexts["Log Out"].tap()
        sleep(2)
        app.alerts["Logging out will remove all of @nanorabbit’s WordPress.com data from this device."].buttons["Log Out"].tap()
        sleep(2)
    }

    
}
