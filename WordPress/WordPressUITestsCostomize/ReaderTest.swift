//
//  ReaderTest.swift
//  WordPress
//
//  Created by Xue Qin on 1/4/18.
//  Copyright © 2018 WordPress. All rights reserved.
//

import XCTest

class ReaderTest: WordPressUITestsCostomize {
    func testReader() {
        

        app.tabBars["Main Navigation"].buttons["readerTabButton"].tap()
        
        // followed Sites
        if app.navigationBars["Followed Sites"].buttons["Reader"].exists {
            app.swipeUp()
            app.swipeUp()
            sleep(2)
            app.navigationBars["Followed Sites"].buttons["Reader"].tap()
        } else {
            app.tables.staticTexts["Followed Sites"].tap()
            app.swipeUp()
            app.swipeUp()
            sleep(2)
            app.navigationBars["Followed Sites"].buttons["Reader"].tap()
            sleep(2)
        }
        
        // Discover
        if app.navigationBars["Discover"].buttons["Reader"].exists {
            app.swipeUp()
            app.swipeUp()
            sleep(2)
            app.navigationBars["Discover"].buttons["Reader"].tap()
        } else {
            app.tables.staticTexts["Discover"].tap()
            app.swipeUp()
            app.swipeUp()
            sleep(2)
            app.navigationBars["Discover"].buttons["Reader"].tap()
            sleep(2)
        }
        
        // My Likes
        if app.navigationBars["My Likes"].buttons["Reader"].exists {
            app.swipeUp()
            app.swipeUp()
            sleep(2)
            app.navigationBars["My Likes"].buttons["Reader"].tap()
        } else {
            app.tables.staticTexts["My Likes"].tap()
            app.swipeUp()
            app.swipeUp()
            sleep(2)
            app.navigationBars["My Likes"].buttons["Reader"].tap()
            sleep(2)
        }
        
        // Add Tag
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Add a Tag"].tap()
        app.keys["d"].tap()
        app.keys["o"].tap()
        app.keys["g"].tap()
        tablesQuery.staticTexts["Add Tag"].tap()

    }
}
