//
//  BlockEditorTests.swift
//  WordPressUITests
//
//  Created by Mo Shuheb on 13/08/2021.
//  Copyright © 2021 WordPress. All rights reserved.
//

import XCTest

class BlockEditorTests: XCTestCase {
    private var editorScreen: BlockEditorScreen!

    override func setUpWithError() throws {
        setUpTestSuite()

        try LoginFlow.loginIfNeeded(siteUrl: WPUITestCredentials.testWPcomSiteAddress, email: WPUITestCredentials.testWPcomUserEmail, password: WPUITestCredentials.testWPcomPassword)
        editorScreen = EditorFlow
            .gotoMySiteScreen()
            .tabBar.gotoBlockEditorScreen()
    }

    override func tearDownWithError() throws {
        takeScreenshotOfFailedTest()
        if editorScreen != nil && !TabNavComponent.isVisible() {
            EditorFlow.returnToMainEditorScreen()
            editorScreen.closeEditor()
        }
        try LoginFlow.logoutIfNeeded()
        super.tearDown()
    }

    func testEnteringTextInBlockEditor() {
        let title = getRandomPhrase()
        let content = getRandomContent()
        editorScreen
            .dismissNotificationAlertIfNeeded(.accept)
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .done()
    }

    func testCopyTextBlock() {
        let title = getRandomPhrase()
        let content = getRandomContent()
        editorScreen
            .dismissNotificationAlertIfNeeded(.accept)
            .enterTextInTitle(text: title)
            .addParagraphBlock(withText: content)
            .copyParagraphBlock()
            .pasteAfterParagraphBlock()
            .publish()
            .viewPublishedPost(withTitle: title)
            .verifyEpilogueDisplays(postTitle: title, siteAddress: WPUITestCredentials.testWPcomSitePrimaryAddress)
            .done()
    }
}
