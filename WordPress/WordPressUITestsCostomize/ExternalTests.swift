//
//  ExternalTests.swift
//  WordPress
//
//  Created by Xue Qin on 1/4/18.
//  Copyright © 2018 WordPress. All rights reserved.
//

import XCTest

class ExternalTests: WordPressUITestsCostomize {
        
    func testViewSite() {
        // go to My Site
        if app.tables["Blog Details Table"].staticTexts[siteName].exists {
            
        }else {
            app.tabBars["Main Navigation"].buttons["mySitesTabButton"].tap()
        }
        
        let viewsite = app.tables["Blog Details Table"].staticTexts["View Site"]
        scrollToElement(element: viewsite)
        viewsite.tap()
        
    }
    
}
