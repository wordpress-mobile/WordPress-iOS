import Nimble
@testable import WordPress
import XCTest

class BlogBugFix16782: XCTestCase {

    private var contextManager: TestContextManager!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
    }

    override func tearDown() {
        contextManager = nil
        super.tearDown()
    }

    func testDefaultAdminURLBehavior() {
        let blog = BlogBuilder(contextManager.mainContext).build()

        let adminURL = blog.adminUrl(withPath: "test")
        debugPrint("~~~ adminURL: \(adminURL)")
        // ~~~ adminURL: https://example.com/wp-admin/test

        // Verify the URL is "valid"
        expect(URL(string: adminURL)?.absoluteString).to(beginWith("http"))
    }

    func testAdminURLWithNullXMLRPC() {
        let blog = BlogBuilder(contextManager.mainContext).build()

        blog.xmlrpc = .none

        let adminURL = blog.adminUrl(withPath: "test")
        debugPrint("~~~ adminURL: \(adminURL)")
        // ~~~ adminURL: "(null)test"

        // Verify the URL is "valid"
        XCTExpectFailure()
        expect(URL(string: adminURL)?.absoluteString).to(beginWith("http"))
    }

    func testDefaultLoginURLBehavior() {
        let blog = BlogBuilder(contextManager.mainContext).build()

        let loginURL = blog.loginUrl()
        debugPrint("~~~ loginURL: \(loginURL)")
        // ~~~ loginURL: https://example.com/wp-login.php

        // Verify the URL is "valid"
        expect(URL(string: loginURL)?.absoluteString).to(beginWith("http"))
    }

    func testLoginURLWithNullXMLRPC() {
        let blog = BlogBuilder(contextManager.mainContext).build()

        blog.xmlrpc = .none

        let loginURL = blog.loginUrl()
        debugPrint("~~~ loginURL: \(loginURL)")
        // ~~~ loginURL: [that's it. the value is an empty string]

        // Verify the URL is "valid"
        XCTExpectFailure()
        expect(URL(string: loginURL)?.absoluteString).to(beginWith("http"))
    }

    func testOrgRESTAPIDefaultBehavior() {
        let blog = BlogBuilder(contextManager.mainContext)
            .with(username: "testusers")
            .with(password: "testpassword")
            .with(wordPressVersion: "1")
            .build()

        let api = WordPressOrgRestApi(blog: blog)

        XCTAssertNotNil(api)
    }

    func testOrgRESTAPIWithNullXMLRPC() {
        let blog = BlogBuilder(contextManager.mainContext)
            .with(username: "testusers")
            .with(password: "testpassword")
            .with(wordPressVersion: "1")
            .build()

        blog.xmlrpc = .none

        let api = WordPressOrgRestApi(blog: blog)

        XCTExpectFailure()
        XCTAssertNotNil(api)
    }
}
