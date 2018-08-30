//
//  MySitesTests.swift
//  WordPress
//
//  Created by Xue Qin on 12/14/17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import XCTest

class MySitesTests: WordPressUITestsCostomize {
    
    func navigationDropDown(name: String) {
        if app.navigationBars["Posts"].buttons["Scheduled"].exists {
            app.navigationBars["Posts"].buttons["Scheduled"].tap()
            app.tables.cells.staticTexts[name].tap()
        }
        if app.navigationBars["Posts"].buttons["Published"].exists {
            app.navigationBars["Posts"].buttons["Published"].tap()
            app.tables.cells.staticTexts[name].tap()
        }
        if app.navigationBars["Posts"].buttons["Draft"].exists {
            app.navigationBars["Posts"].buttons["Draft"].tap()
            app.tables.cells.staticTexts[name].tap()
        }
        if app.navigationBars["Posts"].buttons["Trashed"].exists {
            app.navigationBars["Posts"].buttons["Trashed"].tap()
            app.tables.cells.staticTexts[name].tap()
        }
    }
    
    func addDraft() {
        
        app.navigationBars["Posts"].buttons["icon post add"].tap()
        sleep(2)
        let zssrichtexteditorElement = app.webViews.otherElements["ZSSRichTextEditor"]
        let textViewTitle = zssrichtexteditorElement.children(matching: .textView).element(boundBy: 0)
        let textViewContent = zssrichtexteditorElement.children(matching: .textView).element(boundBy: 1)
        
        textViewTitle.tap()
        sleep(2)
        textViewTitle.typeText("christmas")
        sleep(3)
        textViewContent.tap()
        sleep(2)
        textViewContent.typeText("happy")
        sleep(3)
        
        let toolbarsQuery = app.toolbars
        toolbarsQuery.buttons["Bold"].tap()
        toolbarsQuery.buttons["Italic"].tap()
        toolbarsQuery.buttons["Block Quote"].tap()
        toolbarsQuery.buttons["Unordered List"].tap()
        toolbarsQuery.buttons["Ordered List"].tap()
        toolbarsQuery.buttons["Insert Link"].tap()
        app.alerts["Insert"].buttons["Cancel"].tap()
        
        let htmlButton = toolbarsQuery.buttons["HTML"]
        htmlButton.tap()
        htmlButton.tap()
        
        let wppostviewNavigationBar = app.navigationBars["WPPostView"]
        let button = wppostviewNavigationBar.children(matching: .button).element(boundBy: 3)
        button.tap()
        
        let sheetsQuery = app.sheets
        sheetsQuery.buttons["Preview"].tap()
        app.navigationBars["Preview"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).tap()
        button.tap()
        sheetsQuery.buttons["Save as Draft"].tap()

    }
    
    func addScheduled() {
        app.navigationBars["Posts"].buttons["icon post add"].tap()
        sleep(2)
        let zssrichtexteditorElement = app.webViews.otherElements["ZSSRichTextEditor"]
        let textViewTitle = zssrichtexteditorElement.children(matching: .textView).element(boundBy: 0)
        let textViewContent = zssrichtexteditorElement.children(matching: .textView).element(boundBy: 1)
        
        textViewTitle.tap()
        sleep(2)
        textViewTitle.typeText("To do")
        sleep(3)
        textViewContent.tap()
        sleep(2)
        textViewContent.typeText("Read a book")
        sleep(3)
        
        app.navigationBars["WPPostView"].children(matching: .button).element(boundBy: 3).tap()
        app.sheets.buttons["Options"].tap()
        
        let settingstableTable = app.tables["SettingsTable"]
        settingstableTable.staticTexts["Immediately"].tap()
        
        let todayPickerWheel = settingstableTable.pickerWheels["Today"]
        todayPickerWheel.swipeUp()
        settingstableTable.buttons["Done"].tap()
        
        app.navigationBars["Options"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).tap()
        app.navigationBars["WPPostView"].buttons["Schedule"].tap()
        app.navigationBars.buttons["Done"].tap()
    }
    /*
    func testStatPeriodUnit() {
        
        app.tables["Blog Details Table"].staticTexts["Stats"].tap()
        
        let moreButton = app.segmentedControls.buttons["More…"]
        moreButton.tap()
        
        let selectPeriodUnitSheet = app.sheets["Select Period Unit"]
        selectPeriodUnitSheet.buttons["Years"].tap()
        
        moreButton.tap()
        selectPeriodUnitSheet.buttons["Months"].tap()
        moreButton.tap()
        selectPeriodUnitSheet.buttons["Weeks"].tap()
        moreButton.tap()
        selectPeriodUnitSheet.buttons["Days"].tap()
        
        let videoLabel = app.tables.cells.staticTexts["Videos"]
        scrollToElement(element: videoLabel)
        
        app.navigationBars["Stats"].buttons[siteName].tap()
        
    }
    
    func testInsightsViews() {
        
        app.tables["Blog Details Table"].staticTexts["Stats"].tap()
        app.buttons["Insights"].tap()
        app.tables.children(matching: .cell).element(boundBy: 2).staticTexts["VIEWS"].tap()
        
        let recentWeeks = app.tables.cells.staticTexts["Recent Weeks"]
        scrollToElement(element: recentWeeks)
        
    }
    
    func testInsightsPostingActivity() {
        app.tables["Blog Details Table"].staticTexts["Stats"].tap()
        app.buttons["Insights"].tap()
        
        let postActivity = app.tables.cells.staticTexts["Posting Activity"]
        scrollToElement(element: postActivity)
        postActivity.tap()
        
    }
    
    func testInsightsComments() {
        
    }
    
    func testInsightsTagsandCats() {
        
    }
    
    func testInsightsFollower() {
        
    }
     */

    func testPlans() {
        
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        app.tables["Blog Details Table"].staticTexts["Plans"].tap()
        
        app.tables.cells.staticTexts["Free CURRENT PLAN"].tap()
        app.navigationBars["Free"].buttons["Close"].tap()
        
        app.tables.cells.staticTexts["Personal "].tap()
        app.navigationBars["Personal"].buttons["Close"].tap()
        
        app.tables.cells.staticTexts["Premium "].tap()
        app.navigationBars["Premium"].buttons["Close"].tap()
        
        app.tables.cells.staticTexts["Business "].tap()
        app.navigationBars["Business"].buttons["Close"].tap()
        
    }
    
    func testBlogPostAddDraft() {

        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        app.tables["Blog Details Table"].staticTexts["Blog Posts"].tap()
        navigationDropDown(name: "Published")
        //addDraft()
        
    }
    
    func testBlogPostAddScheduled() {
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        app.tables["Blog Details Table"].staticTexts["Blog Posts"].tap()
        navigationDropDown(name: "Scheduled")
        //addScheduled()
    }
    
    
    func testBlogPostOptions1() {
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        // add title and go to options
        app.tables["Blog Details Table"].staticTexts["Blog Posts"].tap()
        app.navigationBars["Posts"].buttons["icon post add"].tap()
        
        let optiontitle = app.textViews["Content"].textFields["Enter title here"]
        optiontitle.tap()
        optiontitle.typeText("Optionone")
        app.navigationBars[siteName].buttons["Options"].tap()
        
        let settingtable = app.tables["SettingsTable"]
        //category
        settingtable.staticTexts["Categories"].tap()
        app.navigationBars["Post Categories"].buttons["icon post add"].tap()

        let tablesQuery = app.tables
        tablesQuery.cells.textFields["Title"].tap()
        sleep(2)
        app.typeText("W")
        app.typeText("i")
        app.typeText("s")
        app.typeText("h")
        app.buttons["Done"].tap()
        
        tablesQuery.staticTexts["Parent Category"].tap()
        let uncategorizedStaticText = app.tables["CategoriesList"].cells.staticTexts["Uncategorized"]
        uncategorizedStaticText.tap()

        app.navigationBars["Add a Category"].buttons["Save"].tap()
        app.navigationBars["Post Categories"].buttons["Options"].tap()
        
        // Add tag
        settingtable.staticTexts["Tags"].tap()
        sleep(2)
        app.keys["u"].tap()
        app.navigationBars["Tags"].buttons["Options"].tap()
        
        // Status: pending review
        settingtable.staticTexts["Status"].tap()
        tablesQuery.cells.staticTexts["Pending review"].tap()
        
        // visibility: password protection
        settingtable.staticTexts["Visibility"].tap()
        tablesQuery.staticTexts["Password protected"].tap()
        settingtable.secureTextFields["Password Value"].tap()
        let passwordValueSecureTextField = settingtable.secureTextFields["Password Value"]
        passwordValueSecureTextField.typeText("utsa")
        app.buttons["Done"].tap()
        
        
        // add location
        let location = app.tables["SettingsTable"].cells.staticTexts["Set Location"]
        scrollToElement(element: location)
        location.tap()
        app.navigationBars["Location"].buttons["Done"].tap()
        
        // slug
        let slug = app.tables["SettingsTable"].staticTexts["Slug"]
        scrollToElement(element: slug)
        slug.tap()
        app.navigationBars["Slug"].buttons["Options"].tap()
        
        // excerpt
        let excerpt = app.tables["SettingsTable"].staticTexts["Excerpt"]
        scrollToElement(element: excerpt)
        excerpt.tap()
        app.keys["U"].tap()
        app.keys["i"].tap()
        app.navigationBars["Excerpt"].buttons["Options"].tap()
        
        app.navigationBars["Options"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).tap()
        app.navigationBars[siteName].buttons["Save"].tap()
        sleep(3)
        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
        app.navigationBars["Posts"].buttons[siteName].tap()
        
    }
    
    func testBlogPostOptions2() {
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        // add title and go to options
        app.tables["Blog Details Table"].staticTexts["Blog Posts"].tap()
        app.navigationBars["Posts"].buttons["icon post add"].tap()
        
        let optiontitle = app.textViews["Content"].textFields["Enter title here"]
        optiontitle.tap()
        optiontitle.typeText("Optionone")
        app.navigationBars[siteName].buttons["Options"].tap()
        
        let settingtable = app.tables["SettingsTable"]
        
        
        settingtable.staticTexts["Visibility"].tap()
        app.tables.staticTexts["Private"].tap()
        app.navigationBars["Options"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).tap()
        sleep(1)
        //preview
        app.navigationBars[siteName].buttons["Preview"].tap()
        sleep(1)
        app.navigationBars["Preview"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).tap()
        sleep(1)
        app.navigationBars[siteName].buttons["Save"].tap()
        sleep(3)

        if app.navigationBars.buttons["Done"].exists {
            app.navigationBars.buttons["Done"].tap()
        }
        app.navigationBars["Posts"].buttons[siteName].tap()
        
        
    }
    
    func testBlogPostAddPublished() {
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        app.tables["Blog Details Table"].staticTexts["Blog Posts"].tap()
        navigationDropDown(name: "Published")
        app.navigationBars["Posts"].buttons["icon post add"].tap()
        sleep(2)
        
        //tiltle
        let title = app.textViews["Content"].textFields["Enter title here"]
        title.tap()
        title.typeText("Title")
        // content
        app.textViews["Content"].typeText("\n")
        let contentTextView = app.textViews["Content"]
        contentTextView.typeText("Content")
        //app.keys["o"].tap()
        let toolbarsQuery = app.toolbars
        toolbarsQuery.buttons["strong"].tap()
        toolbarsQuery.buttons["em"].tap()
        toolbarsQuery.buttons["u"].tap()
        toolbarsQuery.buttons["del"].tap()
        toolbarsQuery.buttons["link"].tap()
        sleep(2)
        // add link
        let linkUrlTextField = app.alerts["Add a Link"].collectionViews.textFields["Link URL"]
        linkUrlTextField.tap()
        linkUrlTextField.typeText("www.google.com")
        app.alerts["Add a Link"].buttons["Insert"].tap()
        sleep(2)
        toolbarsQuery.buttons["blockquote"].tap()
        toolbarsQuery.buttons["more"].tap()
        //toolbarsQuery.buttons["add media"].tap()
        //sleep(1)
        //app.collectionViews.cells["Image, August 8, 2012 4:29 PM"].tap()
        //app.navigationBars["Camera Roll ▾"].buttons["Done"].tap()
        //sleep(2)
        
        // publish
        app.navigationBars[siteName].buttons["Publish"].tap()
        sleep(5)
        app.buttons["View Post"].tap()
        sleep(1)
        app.swipeUp()
        app.navigationBars["Preview"].buttons["Done"].tap()
        sleep(1)
        app.navigationBars.buttons["Done"].tap()
        sleep(2)
        app.navigationBars["Posts"].buttons["Happy Doge"].tap()

    }
 
    
    /*
    func testPagesAddDraft() {
        
    }
    
    func testPagesAddScheduled() {
        
    }
    
    func testPagesAddOptions() {
        
    }
    
    func testPagesAddPublished() {
        
    }
    
    func testMediaAddAndDelete() {
        // Add and delete photos in media pool
    }
    
    func testMediaEditPicture() {
        // Edit a particular photo
    }
    
    func testExample2() {
        /*let app = XCUIApplication()
        app.navigationBars["Site Title"].buttons["Switch Site"].tap()
        app.navigationBars["My Sites"].buttons["Edit"].tap()
        let blogsTable = app.tables["Blogs"]
        blogsTable.switches["Switch-Visibility-Site Title"].tap()
        blogsTable.switches["Switch-Visibility-Site Title"].tap()
        app.navigationBars["My Sites"].buttons["Edit"].tap()
        blogsTable.staticTexts["nanorabbit.wordpress.com"].tap()
        */
        
        /*let app = XCUIApplication()
        app.navigationBars["Site Title"].buttons["Switch Site"].tap()
        
        let mySitesNavigationBar = app.navigationBars["My Sites"]
        mySitesNavigationBar.buttons["Edit"].tap()
        
        let blogsTable = app.tables["Blogs"]
        blogsTable.switches["Switch-Visibility-Site Title"].tap()
        blogsTable.switches["Switch-Visibility-Site Title"].tap()
        mySitesNavigationBar.buttons["Edit"].tap()
        mySitesNavigationBar.buttons["icon post add"].tap()
        app.sheets.buttons["Create WordPress.com site"].tap()
        XCUIApplication().textFields["Title"].tap()
        XCUIApplication().navigationBars["My Sites"].buttons["icon post add"].tap()
        XCUIApplication().textFields["Site Address"].tap()
        
        let app = XCUIApplication()
        app.buttons["Create Site"].tap()
        app.buttons["OK"].tap()
        
        let app = XCUIApplication()
        app.buttons["Create Site"].tap()
        app.buttons["OK"].tap()*/
        
        /*XCUIApplication().tables["Blog Details Table"].staticTexts["Stats"].tap()
        
        let app = XCUIApplication()
        app.buttons["Days"].tap()
        
        let moreButton = app.buttons["More…"]
        moreButton.tap()
        
        let selectPeriodUnitSheet = app.sheets["Select Period Unit"]
        selectPeriodUnitSheet.buttons["Days"].tap()
        moreButton.tap()
        selectPeriodUnitSheet.buttons["Weeks"].tap()
        moreButton.tap()
        selectPeriodUnitSheet.buttons["Months"].tap()
        moreButton.tap()
        selectPeriodUnitSheet.buttons["Years"].tap()
        
        let webViewsQuery = XCUIApplication().webViews
        XCUIApplication().tables.staticTexts["Posting Activity"].tap()
        XCUIApplication().collectionViews.children(matching: .cell).element(boundBy: 7).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.swipeRight()
        
        app.navigationBars["Posting Activity"].buttons["Stats"].tap()
        //app.navigationBars["Site Title"].buttons["Switch Site"].tap()
        
        
        let tablesQuery = XCUIApplication().tables
        tablesQuery.buttons["By Authors"].tap()
        tablesQuery.buttons["By Posts & Pages"].tap()
        
        let tablesQuery = XCUIApplication().tables
        tablesQuery.buttons["Email"].tap()
        tablesQuery.buttons["WordPress.com"].tap() */
        //XCUIApplication().tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        
        
        let app = XCUIApplication()
        app.navigationBars["EditPageView"].buttons["Cancel"].tap()
        app.navigationBars["Pages"].buttons["Back"].tap()
        
        
        

        
        
    }
 */
    
}
