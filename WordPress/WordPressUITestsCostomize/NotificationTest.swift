//
//  NotificationTest.swift
//  WordPress
//
//  Created by Xue Qin on 1/4/18.
//  Copyright © 2018 WordPress. All rights reserved.
//

import XCTest

class NotificationTest: WordPressUITestsCostomize {
    
    func testNotification() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        app.tabBars["Main Navigation"].buttons["Notifications"].tap()
        
        let notificationsTableTable = app.tables["Notifications Table"]
        notificationsTableTable.buttons["All"].tap()
        sleep(1)
        notificationsTableTable.buttons["Unread"].tap()
        sleep(1)
        notificationsTableTable.buttons["Comments"].tap()
        sleep(1)
        app.tables["Notifications Table"].buttons["Follows"].tap()
        sleep(1)
        notificationsTableTable.buttons["Likes"].tap()
        sleep(1)
        XCUIApplication().tabBars["Main Navigation"].buttons["My Sites"].tap()
        
        
    }
    
}
