//
//  ConfigureTests.swift
//  WordPress
//
//  Created by Xue Qin on 1/2/18.
//  Copyright © 2018 WordPress. All rights reserved.
//

import XCTest

class ConfigureTests: WordPressUITestsCostomize {
        
    /* test all the configures settings in my sites page*/
    
    func testSharing() {
        
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        let sharingButton = app.tables["Blog Details Table"].staticTexts["Sharing"]
        scrollToElement(element: sharingButton)
        sharingButton.tap()
        
        app.tables.staticTexts["Facebook"].tap()
        sleep(3)
        app.navigationBars["Facebook"].buttons["Sharing"].tap()
        
        app.tables.staticTexts["LinkedIn"].tap()
        sleep(3)
        app.navigationBars["LinkedIn"].buttons["Sharing"].tap()
        
        app.tables.staticTexts["Path"].tap()
        sleep(3)
        app.navigationBars["Path"].buttons["Sharing"].tap()
        
        app.tables.staticTexts["Tumblr"].tap()
        sleep(3)
        app.navigationBars["Tumblr"].buttons["Sharing"].tap()
        
        app.tables.staticTexts["Twitter"].tap()
        sleep(3)
        app.navigationBars["Twitter"].buttons["Sharing"].tap()
        
        //return
        app.navigationBars["Sharing"].buttons[siteName].tap()
        
    }
    
    func testSharingButtons() {
        
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        sleep(3)
        let sharingButton = app.tables["Blog Details Table"].staticTexts["Sharing"]
        scrollToElement(element: sharingButton)
        sharingButton.tap()
        sleep(3)
        app.tables.staticTexts["Manage"].tap()
        
        let tablesQuery = app.tables
        
        let editsharingbutton = tablesQuery.switches["Edit sharing buttons"]
        scrollToElement(element: editsharingbutton)
        editsharingbutton.tap()
        
        let pressthisbutton = tablesQuery.switches["Press This"]
        scrollToElement(element: pressthisbutton)
        pressthisbutton.tap()

        
        let twitterbutton = tablesQuery.switches["Twitter"]
        scrollToElement(element: twitterbutton)
        twitterbutton.tap()
        twitterbutton.tap()
        
        let facebookbutton = tablesQuery.switches["Facebook"]
        scrollToElement(element: facebookbutton)
        facebookbutton.tap()
        facebookbutton.tap()
        
        // label
        let labelbutton = tablesQuery.staticTexts["Label"]
        scrollToElement(element: labelbutton)
        labelbutton.tap()
        sleep(2)
        app.keys["w"].tap()
        app.buttons["Done"].tap()

        //Button Style
        let buttonStyle = tablesQuery.cells.staticTexts["Button Style"]
        scrollToElement(element: buttonStyle)
        buttonStyle.tap()
        tablesQuery.staticTexts["Text Only"].tap()
        tablesQuery.staticTexts["Official Buttons"].tap()
        tablesQuery.staticTexts["Icon Only"].tap()
        tablesQuery.staticTexts["Icon & Text"].tap()
        app.navigationBars["Button Style"].buttons["Manage"].tap()
        
        // Reblog & Like
        let reblogbutton = tablesQuery.cells.staticTexts.matching(identifier: "Show Reblog button").element(boundBy: 0)
        scrollToElement(element: reblogbutton)
        reblogbutton.tap()

        
        let likebutton = tablesQuery.cells.staticTexts.matching(identifier: "Show Like button").element(boundBy: 0)
        scrollToElement(element: likebutton)
        likebutton.tap()
        likebutton.tap()
        
        let commentlikebutton = tablesQuery.cells.staticTexts.matching(identifier: "Comment Likes").element(boundBy: 0)
        scrollToElement(element: commentlikebutton)
        commentlikebutton.tap()
        commentlikebutton.tap()
        
        // Twitter username
        let twittername = tablesQuery.cells.staticTexts.matching(identifier: "Twitter Username").element(boundBy: 0)
        if twittername.exists {
            twittername.tap()
            app.navigationBars["Twitter Username"].buttons["Manage"].tap()
        }

        // return to mysite page
        app.navigationBars["Manage"].buttons["Sharing"].tap()
        
    }
    
    func testPeopleButton() {
        
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        let tablesQuery = app.tables
        
        // enter people section
        sleep(2)
        let peoplebutton = app.tables["Blog Details Table"].staticTexts["People"]
        scrollToElement(element: peoplebutton)
        peoplebutton.tap()
        
        //check current user
        app.tables.cells.staticTexts["Administrator"].tap()
        sleep(2)
        app.navigationBars["UI Privacy"].buttons["Users"].tap()
        
        // add people
        let addbutton = app.navigationBars["Users"].buttons["Add"]
        addbutton.tap()
        sleep(2)
        
        tablesQuery.cells.staticTexts["Email or Username..."].tap()
        let userfield = tablesQuery.cells.textFields.matching(identifier: "Email or Username...").element(boundBy: 0)
        userfield.typeText("guileakutsa")
        app.buttons["Done"].tap()
        
        tablesQuery.staticTexts["Role"].tap()
        app.tables.cells.staticTexts["Follower"].tap()
        if app.navigationBars["Role"].buttons["Add a Person"].exists {
            app.navigationBars["Role"].buttons["Add a Person"].tap()
        }
        
        tablesQuery.children(matching: .cell).element(boundBy: 2).tap()
        app.keys["h"].tap()
        app.keys["e"].tap()
        app.keys["l"].tap()
        app.keys["l"].tap()
        app.keys["o"].tap()
        app.navigationBars["Message"].buttons["Add a Person"].tap()
        
        let invitebutton = app.navigationBars["Add a Person"].buttons["Invite"]
        if invitebutton.isEnabled {
            invitebutton.tap()
        }
        
    }
    
    func testGeneralSettings() {
        
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        let tablesQuery = app.tables
        
        // enter settings section
        sleep(2)
        let settingsbutton = app.tables["Blog Details Table"].staticTexts["Settings"]
        scrollToElement(element: settingsbutton)
        settingsbutton.tap()
        
        // site title
        tablesQuery.staticTexts["Site Title"].tap()
        app.navigationBars["Site Title"].buttons["Settings"].tap()
        
        // tagline
        tablesQuery.staticTexts["Tagline"].tap()
        app.keyboards.keys["s"].tap()
        app.navigationBars["Tagline"].buttons["Settings"].tap()
        
        // privacy
        tablesQuery.staticTexts["Privacy"].tap()
        tablesQuery.staticTexts["Private"].tap()
        tablesQuery.staticTexts["Hidden"].tap()
        tablesQuery.staticTexts["Public"].tap()
        app.navigationBars["Privacy"].buttons["Settings"].tap()
        
        // language
        tablesQuery.cells.staticTexts["Language"].tap()
        tablesQuery.cells.staticTexts["Language"].tap()
        app.navigationBars["Site Language"].buttons["Language"].tap()
        app.navigationBars["Language"].buttons["Settings"].tap()
        
    }
    
    func testWritingSettings() {
        
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        let tablesQuery = app.tables
        // enter settings section
        sleep(2)
        let settingsbutton = app.tables["Blog Details Table"].staticTexts["Settings"]
        scrollToElement(element: settingsbutton)
        settingsbutton.tap()
        
        // default category
        tablesQuery.staticTexts["Default Category"].tap()
        app.navigationBars["Default Category"].buttons["icon post add"].tap()
        let titlefield = tablesQuery.cells.textFields["Title"]
        titlefield.tap()
        titlefield.typeText("dog")
        tablesQuery.staticTexts["Parent Category"].tap()
        app.tables["CategoriesList"].staticTexts["Uncategorized"].tap()
        app.navigationBars["Add a Category"].buttons["Save"].tap()
        sleep(3)
        app.tables["CategoriesList"].staticTexts["dog"].tap()
        app.navigationBars["Default Category"].buttons["Settings"].tap()
        
        // default post format
        tablesQuery.staticTexts["Default Post Format"].tap()
        app.navigationBars["Default Post Format"].buttons["Settings"].tap()
        
        // related posts
        tablesQuery.staticTexts["Related Posts"].tap()
        if tablesQuery.cells.staticTexts.matching(identifier: "Show Header").element(boundBy: 0).exists {
            tablesQuery.cells.staticTexts.matching(identifier: "Show Header").element(boundBy: 0).tap()
            sleep(2)
            tablesQuery.cells.staticTexts.matching(identifier: "Show Images").element(boundBy: 0).tap()
        } else {
            tablesQuery.cells.staticTexts.matching(identifier: "Show Related Posts").element(boundBy: 0).tap()
            sleep(2)
            tablesQuery.cells.staticTexts.matching(identifier: "Show Header").element(boundBy: 0).tap()
            sleep(2)
            tablesQuery.cells.staticTexts.matching(identifier: "Show Images").element(boundBy: 0).tap()
        }
        app.navigationBars["Related Posts"].buttons["Settings"].tap()
        
    }
    
    func testDiscussionSettings() {
        
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        let tablesQuery = app.tables
        // enter settings section
        sleep(2)
        let settingsbutton = app.tables["Blog Details Table"].staticTexts["Settings"]
        scrollToElement(element: settingsbutton)
        settingsbutton.tap()
        
        // enter discussion section
        tablesQuery.staticTexts["Discussion"].tap()
        
        let allowswitch = tablesQuery.switches["Allow Comments"]
        scrollToElement(element: allowswitch)
        allowswitch.tap()
        allowswitch.tap()
        
        let sendswitch = tablesQuery.switches["Send Pingbacks"]
        scrollToElement(element: sendswitch)
        sendswitch.tap()
        sendswitch.tap()
        
        let receiveswitch = tablesQuery.switches["Receive Pingbacks"]
        scrollToElement(element: receiveswitch)
        receiveswitch.tap()
        receiveswitch.tap()
        
        let emailswitch = tablesQuery.switches["Require name and email"]
        scrollToElement(element: emailswitch)
        emailswitch.tap()
        emailswitch.tap()
        
        let loginswitch = tablesQuery.switches["Require users to log in"]
        scrollToElement(element: loginswitch)
        loginswitch.tap()

        tablesQuery.cells.staticTexts["Close Commenting"].tap()
        let timerpicker = app.pickerWheels.element(boundBy: 0)
        timerpicker.adjust(toPickerWheelValue: "20 days")
        app.navigationBars["Close commenting"].buttons["Discussion"].tap()
        
        
        tablesQuery.staticTexts["Sort By"].tap()
        tablesQuery.staticTexts["Newest first"].tap()
        app.navigationBars["Sort By"].buttons["Discussion"].tap()
        
        tablesQuery.staticTexts["Threading"].tap()
        tablesQuery.staticTexts["Four levels"].tap()
        app.navigationBars["Threading"].buttons["Discussion"].tap()
        
        tablesQuery.staticTexts["Paging"].tap()
        let daypicker = app.pickerWheels.element(boundBy: 0)
        daypicker.adjust(toPickerWheelValue: "50")
        app.navigationBars["Paging"].buttons["Discussion"].tap()
        
        //automatically approve
        tablesQuery.staticTexts["Automatically Approve"].tap()
        tablesQuery.staticTexts["No comments"].tap()
        tablesQuery.staticTexts["Known user's comments"].tap()
        app.navigationBars["Automatically Approve"].buttons["Discussion"].tap()
        
        //links in comments
        let linkincomments = tablesQuery.staticTexts["Links in comments"]
        scrollToElement(element: linkincomments)
        linkincomments.tap()
        let linkpicker = app.pickerWheels.element(boundBy: 0)
        linkpicker.adjust(toPickerWheelValue: "4")
        app.navigationBars["Links in comments"].buttons["Discussion"].tap()
        
        //hold for moderation
        let moderation = tablesQuery.staticTexts["Hold for Moderation"]
        scrollToElement(element: moderation)
        moderation.tap()
        
        app.navigationBars["Hold for Moderation"].buttons["Add"].tap()
        app.keyboards.keys["U"].tap()
        app.keyboards.keys["t"].tap()
        app.buttons["Done"].tap()
        app.navigationBars["Hold for Moderation"].buttons["Discussion"].tap()
        
        //blacklist
        let blacklist = tablesQuery.staticTexts["Blacklist"]
        scrollToElement(element: blacklist)
        blacklist.tap()
        
        app.navigationBars["Blacklist"].buttons["Add"].tap()
        app.keyboards.keys["E"].tap()
        app.keyboards.keys["y"].tap()
        app.keyboards.keys["e"].tap()
        app.buttons["Done"].tap()
        app.navigationBars["Blacklist"].buttons["Discussion"].tap()
        app.navigationBars["Discussion"].buttons["Settings"].tap()

    }
    
    func testAdvancedSettings() {
        
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }

        let tablesQuery = app.tables
        // enter settings section
        sleep(2)
        let settingsbutton = app.tables["Blog Details Table"].staticTexts["Settings"]
        scrollToElement(element: settingsbutton)
        settingsbutton.tap()
        
        let deletesite = tablesQuery.staticTexts["Delete Site"]
        scrollToElement(element: deletesite)
        deletesite.tap()
        app.navigationBars["Delete Site"].buttons["Settings"].tap()
        
        let exportcontent = tablesQuery.staticTexts["Export Content"]
        scrollToElement(element: exportcontent)
        exportcontent.tap()
        sleep(1)
        app.alerts["Export Your Content"].buttons["Export Content"].tap()
        sleep(5)
        
        let startover = tablesQuery.staticTexts["Start Over"]
        scrollToElement(element: startover)
        startover.tap()
        
    }
    
}
