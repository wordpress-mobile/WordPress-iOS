//
//  PublishTest.swift
//  WordPress
//
//  Created by Xue Qin on 2/16/18.
//  Copyright © 2018 WordPress. All rights reserved.
//

import XCTest

class PublishTest: WordPressUITestsCostomize {
    
    
    func testBlogPosts() {
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        app.tables["Blog Details Table"].staticTexts["Blog Posts"].tap()
        app.swipeUp()
        app.navigationBars["Posts"].buttons["Happy Doge"].tap()
        
 
    }
    
    func testPages() {
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        app.tables["Blog Details Table"].staticTexts["Pages"].tap()
        app.navigationBars["Pages"].buttons[siteName].tap()
        
    }
    
    func testMedia() {
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }

        app.tables["Blog Details Table"].staticTexts["Media"].tap()
        
        let mediaNavigationBar = app.navigationBars["Media"]
        mediaNavigationBar.buttons[siteName].tap()
        
    }
    
    func testComments() {
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }

        app.tables["Blog Details Table"].staticTexts["Comments"].tap()
        app.navigationBars["Comments"].buttons[siteName].tap()
        
    }
    
}
