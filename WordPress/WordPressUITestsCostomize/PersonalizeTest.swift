//
//  PersonalizeTest.swift
//  WordPress
//
//  Created by Xue Qin on 1/3/18.
//  Copyright © 2018 WordPress. All rights reserved.
//

import XCTest

class PersonalizeTest: WordPressUITestsCostomize {
        
    func testThemes() {
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        //enter themes section
        app.tables["Blog Details Table"].staticTexts["Themes"].tap()
        sleep(2)
        app.swipeUp()
        app.swipeUp()
        app.navigationBars["Themes"].buttons[siteName].tap()
        
        
    }
    
    func testMenus1() {
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        /* primary use */
        let menusButton = app.tables["Blog Details Table"].staticTexts["Menus"]
        scrollToElement(element: menusButton)
        menusButton.tap()
        
        
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.staticTexts["2 menu areas in this theme"].tap()
        elementsQuery.staticTexts.matching(identifier: "Header").element(boundBy: 0).tap()
        
        elementsQuery.staticTexts["3 menus available"].tap()
        elementsQuery.staticTexts.matching(identifier: "Primary").element(boundBy: 0).tap()
        
        
        if elementsQuery.staticTexts["About"].exists {
            elementsQuery.staticTexts["About"].tap()
            app.tables.staticTexts["Appium"].tap()
            app.buttons["OK"].tap()
        } else if elementsQuery.staticTexts["Appium"].exists {
            elementsQuery.staticTexts["Appium"].tap()
            app.tables.staticTexts["About"].tap()
            app.buttons["OK"].tap()
        }

        let menusNavigationBar = app.navigationBars["Menus"]
        menusNavigationBar.buttons["Save"].tap()
   
    }
    
    func testMenus2() {
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        /* social use */
        let menusButton = app.tables["Blog Details Table"].staticTexts["Menus"]
        scrollToElement(element: menusButton)
        menusButton.tap()
        
        
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.staticTexts["2 menu areas in this theme"].tap()
        elementsQuery.staticTexts.matching(identifier: "Header").element(boundBy: 0).tap()
        
        elementsQuery.staticTexts["3 menus available"].tap()
        elementsQuery.staticTexts.matching(identifier: "Social Media").element(boundBy: 0).tap()
        
        
        elementsQuery.staticTexts["Facebook"].tap()
        app.tables["LINK ADDRESS (URL), Open link in new window/tab"].staticTexts["Open link in new window/tab"].tap()
        app.buttons["OK"].tap()
        
        let menusNavigationBar = app.navigationBars["Menus"]
        menusNavigationBar.buttons["Save"].tap()

    }
    
}
