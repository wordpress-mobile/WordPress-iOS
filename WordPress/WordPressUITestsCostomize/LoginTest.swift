//
//  LoginTest.swift
//  WordPress
//
//  Created by Xue Qin on 12/14/17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import XCTest

class LoginTest: WordPressUITestsCostomize {
    
    
    
    func testlogout() {
        
        logout()
        emailLogin()
        
    }
    
    func testRegister() {
        
        logout()
        sleep(2)
        
        app.buttons["Create a WordPress site"].tap()
        let emailfiled = app.textFields["Email Address"]
        emailfiled.tap()
        emailfiled.typeText("ui")
        
        let usernamefiled = app.textFields["Username"]
        usernamefiled.tap()
        usernamefiled.typeText("guileakutsa")
        
        let password = app.secureTextFields["Password"]
        password.tap()
        password.typeText("utsa123456")
        
        //let urlfield = app.textFields["Site Address (URL)"]
        //urlfield.tap()
        //urlfield.typeText("guileakutsa")
        
        sleep(2)
        let createaccountbuttonButton = app.buttons["CREATE ACCOUNT"]
        createaccountbuttonButton.tap()
        sleep(2)
        app.buttons["Need more help?"].tap()
        sleep(2)
        emailfiled.typeText("@126.org")
        createaccountbuttonButton.tap()
        app.buttons["OK"].tap()
        
        sleep(2)
        app.buttons["By creating an account you agree to the fascinating Terms of Service."].tap()
        
    }
    
    func testSiteLogin() {
        
        logout()
        
        sleep(2)
        app.buttons["Log In"].tap()
        sleep(1)
        app.buttons["Log into your site by entering your site address instead."].tap()
        sleep(2)
        app.buttons["Need help finding your site address?"].tap()
        sleep(1)
        app.buttons["OK"].tap()
        
        let sitefield = app.textFields["example.wordpress.com"]
        sitefield.tap()
        sitefield.typeText("nanorabbit.wordpress.com")
        sleep(1)
        app.buttons["Next Button"].tap()
        
    }
}
