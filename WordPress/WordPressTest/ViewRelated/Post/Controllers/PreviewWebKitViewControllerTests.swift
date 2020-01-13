//
//  PreviewWebKitViewController.swift
//  WordPressTest
//
//  Created by Brandon Titus on 1/13/20.
//  Copyright © 2020 WordPress. All rights reserved.
//

import XCTest
@testable import WordPress

class PreviewWebKitViewControllerTests: XCTestCase {

    private var rootWindow: UIWindow!
    private var context: NSManagedObjectContext!
    private var navController = UINavigationController()

    override func setUp() {
        super.setUp()
        context = TestContextManager().mainContext

        rootWindow = UIWindow(frame: UIScreen.main.bounds)
        rootWindow.isHidden = false
        rootWindow.rootViewController = navController
    }

    override func tearDown() {
        super.tearDown()
        context = nil
        ContextManager.overrideSharedInstance(nil)
    }

    func testMissingPermalink() {
        let post = PostBuilder(context).drafted().build()

        let vc = PreviewWebKitViewController(post: post, previewURL: nil)
        XCTAssertEqual(vc.url.absoluteString, "about:blank", "Should load blank page when no permalink is available")
    }

    func testDraftToolbarItems() {

        let post = PostBuilder(context).drafted().build()
        post.permaLink = "http://example.com/"

        let vc = PreviewWebKitViewController(post: post, previewURL: nil)
        let items = vc.toolbarItems(linkBehavior: vc.linkBehavior)

        XCTAssertTrue(items.contains(vc.publishButton), "Should contain publish button")
        XCTAssertFalse(items.contains(vc.safariButton),
                       "Should contain back button")
        XCTAssertFalse(items.contains(vc.backButton), "Should contain back button")
        XCTAssertFalse(items.contains(vc.forwardButton), "Should contain back button")
    }

    func testPublishedToolbarItems() {

        let post = PostBuilder(context).published().build()
        post.permaLink = "http://example.com/"

        let vc = PreviewWebKitViewController(post: post, previewURL: nil)
        let items = vc.toolbarItems(linkBehavior: vc.linkBehavior)

        XCTAssertTrue(items.contains(vc.shareButton), "Should contain back button")
        XCTAssertTrue(items.contains(vc.safariButton), "Should contain back button")
        XCTAssertFalse(items.contains(vc.backButton), "Should contain back button")
        XCTAssertFalse(items.contains(vc.forwardButton), "Should contain back button")
    }

    func testSitePageToolbarItems() {

        let page = PageBuilder(context).build()
        page.permaLink = "http://example.com/"

        let vc = PreviewWebKitViewController(post: page, previewURL: nil)
        let items = vc.toolbarItems(linkBehavior: vc.linkBehavior)

        XCTAssertFalse(items.contains(vc.publishButton), "Should contain back button")
        XCTAssertTrue(items.contains(vc.safariButton), "Should contain back button")
        XCTAssertTrue(items.contains(vc.backButton), "Should contain back button")
        XCTAssertTrue(items.contains(vc.forwardButton), "Should contain back button")
    }
}
