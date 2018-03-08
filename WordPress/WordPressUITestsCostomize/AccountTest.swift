//
//  AccountTest.swift
//  WordPress
//
//  Created by Xue Qin on 1/4/18.
//  Copyright © 2018 WordPress. All rights reserved.
//

import XCTest

class AccountTest: WordPressUITestsCostomize {
    
    func testMyProfile() {
        
        let mainNavigationTabBar = app.tabBars["Main Navigation"]
        mainNavigationTabBar.buttons["meTabButton"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["My Profile"].tap()
        
        //first name
        tablesQuery.staticTexts["First Name"].tap()
        app.navigationBars["First Name"].buttons["My Profile"].tap()
        
        //last name
        tablesQuery.staticTexts["Last Name"].tap()
        app.navigationBars["Last Name"].buttons["My Profile"].tap()
        
        //display name
        tablesQuery.staticTexts["Display Name"].tap()
        app.navigationBars["Display Name"].buttons["My Profile"].tap()
        
        //about me
        tablesQuery.staticTexts["About Me"].tap()
        app.keys["s"].tap()
        app.navigationBars["About Me"].buttons["My Profile"].tap()
        sleep(2)
        app.navigationBars["My Profile"].buttons["Me"].tap()
        app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        
    }
    
    func testAccountSettings() {
        
        let mainNavigationTabBar = app.tabBars["Main Navigation"]
        mainNavigationTabBar.buttons["meTabButton"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Account Settings"].tap()
        
        //username

        
        //email
        tablesQuery.staticTexts["Email"].tap()
        app.navigationBars["Email"].buttons["Account Settings"].tap()
        
        
        //primary site
        tablesQuery.staticTexts["Primary Site"].tap()
        app.navigationBars["Primary Site"].buttons["Cancel"].tap()
        
        //web address
        tablesQuery.staticTexts["Web Address"].tap()
        app.navigationBars["Web Address"].buttons["Account Settings"].tap()
        
        app.navigationBars["Account Settings"].buttons["Me"].tap()
        sleep(2)
        app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
    }
    
    func testAppSettings() {
        
        let mainNavigationTabBar = app.tabBars["Main Navigation"]
        mainNavigationTabBar.buttons["meTabButton"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["App Settings"].tap()
        
        //media
        tablesQuery.switches["Remove Location From Media"].tap()
        tablesQuery.staticTexts["Clear Media Cache"].tap()
        
        
        //editor
        let beta = tablesQuery.staticTexts["Beta"]
        scrollToElement(element: beta)
        beta.tap()
        
        let visual = tablesQuery.staticTexts["Visual"]
        scrollToElement(element: visual)
        visual.tap()
        
        let plainText = tablesQuery.staticTexts["Plain Text"]
        scrollToElement(element: plainText)
        plainText.tap()
        
        //usage statistics
        let sendstat = tablesQuery.staticTexts.matching(identifier: "Send Statistics").element(boundBy: 0)
        scrollToElement(element: sendstat)
        sendstat.tap()
        sendstat.tap()
        
        app.navigationBars["App Settings"].buttons["Me"].tap()
        sleep(2)
        app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
    }
    
    func testNotificationSettings() {
        
        let mainNavigationTabBar = app.tabBars["Main Navigation"]
        mainNavigationTabBar.buttons["meTabButton"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Notification Settings"].tap()
        
        //Your Sites
        tablesQuery.staticTexts["nanorabbit.wordpress.com"].tap()
        tablesQuery.staticTexts["Push Notifications"].tap()
        app.navigationBars["Push Notifications"].buttons["Back"].tap()
        
        tablesQuery.staticTexts["Notifications Tab"].tap()
        tablesQuery.switches["Site follows"].tap()
        tablesQuery.switches["Site achievements"].tap()
        tablesQuery.switches["Username mentions"].tap()
        app.navigationBars["Notifications Tab"].buttons["Back"].tap()
        sleep(2)
        if app.alerts["Oops!"].exists {
            sleep(2)
            app.alerts["Oops!"].buttons["Cancel"].tap()
        }
        sleep(1)
        
        tablesQuery.staticTexts["Email"].tap()
        tablesQuery.switches["Username mentions"].tap()
        app.navigationBars["Email"].buttons["Back"].tap()
        sleep(2)
        if app.alerts["Oops!"].exists {
            sleep(2)
            app.alerts["Oops!"].buttons["Cancel"].tap()
        }
        sleep(2)
        app.navigationBars[siteName].buttons["Back"].tap()
        
        //Other
        tablesQuery.staticTexts["Comments on Other Sites"].tap()
        app.navigationBars["Other Sites"].buttons["Back"].tap()
        tablesQuery.staticTexts["Email from WordPress.com"].tap()
        app.navigationBars["Email"].buttons["Back"].tap()
        
        //Return
        app.navigationBars["Notifications"].buttons["Me"].tap()
        app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
    
    }
    
    func testHelpSupport() {
        let mainNavigationTabBar = app.tabBars["Main Navigation"]
        mainNavigationTabBar.buttons["meTabButton"].tap()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Help & Support"].tap()
        
        tablesQuery.switches["Extra Debug"].tap()
        tablesQuery.switches["Extra Debug"].tap()
        
        tablesQuery.staticTexts["Activity Logs"].tap()
        tablesQuery.staticTexts["Clear Old Activity Logs"].tap()
        sleep(2)
        app.navigationBars["Activity Logs"].buttons["Support"].tap()
        sleep(2)
        
        //return
        app.navigationBars["Support"].buttons["Me"].tap()
        sleep(1)
        app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        
        
    }
}
