import UIKit
import XCTest
import OHHTTPStubs
import Nimble
@testable import WordPress

class AccountServiceTests: CoreDataTestCase {
    var accountService: AccountService!

    override func setUp() {
        super.setUp()

        stub(condition: isHost("public-api.wordpress.com")) { request in
            NSLog("[Warning] Received an unexpected request sent to \(String(describing: request.url))")
            return HTTPStubsResponse(error: URLError(.notConnectedToInternet))
        }

        contextManager.useAsSharedInstance(untilTestFinished: self)
        accountService = AccountService(coreDataStack: contextManager)
    }

    override func tearDown() {
        super.tearDown()

        accountService = nil
        HTTPStubs.removeAllStubs()
    }

    func testCreateWordPressComAccountUUID() throws {
        let account = try createAccount(withUsername: "username", authToken: "authtoken")
        XCTAssertNotNil(account.uuid, "UUID should be set")
    }

    func testSetDefaultWordPressComAccountCheckUUID() throws {
        let account = try createAccount(withUsername: "username", authToken: "authtoken")

        accountService.setDefaultWordPressComAccount(account)

        let uuid = UserDefaults.standard.string(forKey: "AccountDefaultDotcomUUID")
        XCTAssertNotNil(uuid, "Default UUID should be set")
        XCTAssertEqual(uuid!, account.uuid, "UUID should be set as default")
    }

    func testGetDefaultWordPressComAccountNoneSet() throws {
        XCTAssertNil(try WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext), "No default account should be set")
    }

    func testGetDefaultWordPressComAccount() throws {
        let account = try createAccount(withUsername: "username", authToken: "authtoken")

        accountService.setDefaultWordPressComAccount(account)

        let defaultAccount = try WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext)
        XCTAssertNotNil(defaultAccount, "Default account should be set")
        XCTAssertTrue(account.isDefaultWordPressComAccount, "Default account should the one created")
    }

    func testNumberOfAccountsNoAccounts() throws {
        XCTAssertEqual(try WPAccount.lookupNumberOfAccounts(in: contextManager.mainContext), 0, "There should be zero accounts")
    }

    func testNumberOfAccountsOneAccount() throws {
        _ = try createAccount(withUsername: "username", authToken: "authtoken")

        XCTAssertEqual(try WPAccount.lookupNumberOfAccounts(in: contextManager.mainContext), 1, "There should be one account")
    }

    func testNumberOfAccountsTwoAccounts() throws {
        _ = try createAccount(withUsername: "username", authToken: "authtoken")
        _ = try createAccount(withUsername: "username2", authToken: "authtoken2")

        try XCTAssertEqual(WPAccount.lookupNumberOfAccounts(in: mainContext), 2, "There should be two accounts")
    }

    func testRemoveDefaultWordPressComAccountNoAccount() {
        accountService.removeDefaultWordPressComAccount()

        XCTAssertTrue(true, "Test passes if no exception thrown")
    }

    func testRemoveDefaultWordPressComAccountAccountSet() throws {
        accountService.removeDefaultWordPressComAccount()

        let account = try createAccount(withUsername: "username", authToken: "authtoken")

        accountService.setDefaultWordPressComAccount(account)

        accountService.removeDefaultWordPressComAccount()

        XCTAssertNil(try WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext), "No default account should be set")
        try XCTAssertEqual(mainContext.count(for: WPAccount.fetchRequest()), 0)
    }

    func testCreateAccountSetsDefaultAccount() throws {
        XCTAssertNil(try WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext))

        let account = try createAccount(withUsername: "username", authToken: "authtoken")
        XCTAssertTrue(account.isDefaultWordPressComAccount)
    }

    func testCreateAccountDoesntReplaceDefaultAccount() throws {
        XCTAssertNil(try WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext))

        let account = try createAccount(withUsername: "username", authToken: "authtoken")
        XCTAssertTrue(account.isDefaultWordPressComAccount)

        _ = try createAccount(withUsername: "another", authToken: "authtoken")
        XCTAssertTrue(account.isDefaultWordPressComAccount)
    }

    func testRestoreDefaultAccount() throws {
        XCTAssertNil(try WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext))

        let account = try createAccount(withUsername: "username", authToken: "authtoken")
        XCTAssertTrue(account.isDefaultWordPressComAccount)

        UserSettings.defaultDotComUUID = nil

        accountService.restoreDisassociatedAccountIfNecessary()
        XCTAssertTrue(account.isDefaultWordPressComAccount)
    }

    func testAccountUsedForJetpackIsNotRestored() throws {
        XCTAssertNil(try WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext))

        let account = try createAccount(withUsername: "username", authToken: "authtoken")
        XCTAssertTrue(account.isDefaultWordPressComAccount)

        let context = contextManager.mainContext
        let jetpackAccount = try createAccount(withUsername: "jetpack", authToken: "jetpack")
        let blog = Blog(context: context)
        blog.xmlrpc = "http://test.blog/xmlrpc.php"
        blog.username = "admin"
        blog.url = "http://test.blog/"
        blog.isHostedAtWPcom = false
        blog.account = jetpackAccount
        contextManager.save(context)

        UserSettings.defaultDotComUUID = nil
        accountService.restoreDisassociatedAccountIfNecessary()
        XCTAssertTrue(account.isDefaultWordPressComAccount)

        accountService.removeDefaultWordPressComAccount()
        XCTAssertNil(try WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext))
    }

    func testMergeMultipleDuplicateAccounts() throws {
        let context = contextManager.mainContext

        let account1 = WPAccount.fixture(context: context, userID: 1)
        let account2 = WPAccount.fixture(context: context, userID: 1)
        let account3 = WPAccount.fixture(context: context, userID: 1)

        account1.addBlogs(createMockBlogs(withIDs: [1, 2, 3, 4, 5, 6], in: context))
        account2.addBlogs(createMockBlogs(withIDs: [1, 2, 3], in: context))
        account3.addBlogs(createMockBlogs(withIDs: [4, 5, 6], in: context))
        contextManager.saveContextAndWait(context)

        try XCTAssertEqual(context.count(for: WPAccount.fetchRequest()), 3)

        accountService.setDefaultWordPressComAccount(account1)

        accountService.mergeDuplicatesIfNecessary()

        try XCTAssertEqual(context.count(for: WPAccount.fetchRequest()), 1)
        try XCTAssertEqual((context.fetch(WPAccount.fetchRequest()).first as? WPAccount)?.uuid, account1.uuid)

        let blogs = (try? BlogQuery().blogs(in: contextManager.mainContext)) ?? []
        XCTAssertEqual(blogs.count, 6)
        XCTAssertTrue(account1.blogs.count == 6)
    }

    func testMergeDuplicateAccountsKeepingNonDups() throws {
        let context = contextManager.mainContext

        let account1 = AccountBuilder(contextManager.mainContext)
            .with(id: 1)
            .with(username: "username")
            .with(authToken: "authToken")
            .with(uuid: UUID().uuidString)
            .build()

        // account2 is a duplicate of account1
        let account2 = AccountBuilder(contextManager.mainContext)
            .with(id: 1)
            .with(username: "username")
            .with(authToken: "authToken")
            .with(uuid: UUID().uuidString)
            .build()

        let account3 = AccountBuilder(contextManager.mainContext)
            .with(id: 3)
            .with(username: "username3")
            .with(authToken: "authToken3")
            .with(uuid: UUID().uuidString)
            .build()

        account1.addBlogs(createMockBlogs(withIDs: [1, 2, 3, 4, 5, 6], in: context))
        account2.addBlogs(createMockBlogs(withIDs: [1, 2, 3], in: context))
        account3.addBlogs(createMockBlogs(withIDs: [4, 5, 6], in: context))
        contextManager.saveContextAndWait(context)
        accountService.setDefaultWordPressComAccount(account1)
        try XCTAssertEqual(context.count(for: WPAccount.fetchRequest()), 3)

        accountService.mergeDuplicatesIfNecessary()
        contextManager.saveContextAndWait(context)
        try XCTAssertEqual(context.count(for: WPAccount.fetchRequest()), 2)

        let accountIds = try context.fetch(WPAccount.fetchRequest()).compactMap { ($0 as? WPAccount)?.uuid }
        XCTAssertEqual(Set(accountIds), Set([account1.uuid, account3.uuid]))
    }

    func createAccount(withUsername username: String, authToken: String) throws -> WPAccount {
        let id = accountService.createOrUpdateAccount(withUsername: username, authToken: authToken)
        return try XCTUnwrap(mainContext.existingObject(with: id) as? WPAccount)
    }

    func createMockBlogs(withIDs IDs: [Int], in context: NSManagedObjectContext) -> Set<Blog> {
        var blogs = Set<Blog>()
        for id in IDs {
            let blog = Blog(context: context)
            blog.dotComID = NSNumber(integerLiteral: id)
            blog.xmlrpc = "http://test.blog/\(id)/xmlrpc.php"
            blog.username = "admin"
            blog.url = "http://test.blog/\(id)"
            blog.isHostedAtWPcom = true
            blogs.insert(blog)
        }
        return blogs
    }

    func testPurgeAccount() throws {
        let account1 = WPAccount.fixture(context: mainContext, userID: 1)
        let account2 = WPAccount.fixture(context: mainContext, userID: 2)

        contextManager.saveContextAndWait(mainContext)
        try XCTAssertEqual(mainContext.count(for: WPAccount.fetchRequest()), 2)

        accountService.purgeAccountIfUnused(account1)
        try XCTAssertEqual(mainContext.count(for: WPAccount.fetchRequest()), 1)

        try DispatchQueue.global().sync {
            self.accountService.purgeAccountIfUnused(account2)
            try XCTAssertEqual(mainContext.count(for: WPAccount.fetchRequest()), 0)
        }
    }

    func testUpdateUserDetails() throws {
        stub(condition: isPath("/rest/v1.1/me")) { _ in
            HTTPStubsResponse(
                jsonObject: [
                    "ID": 55511,
                    "display_name": "Jim Tester",
                    "username": "jimthetester",
                    "email": "jim@wptestaccounts.com",
                    "primary_blog": 55555551,
                    "primary_blog_url": "https://test1.wordpress.com",
                ] as [String: Any],
                statusCode: 200,
                headers: nil
            )
        }

        let account = try createAccount(withUsername: "username", authToken: "token")
        waitUntil { done in
            self.accountService.updateUserDetails(for: account, success: { done() }, failure: { _ in done() })
        }

        expect(account.username).toEventually(equal("jimthetester"))
        expect(account.email).toEventually(equal("jim@wptestaccounts.com"))
    }

    func testChangingBlogVisiblity() throws {
        stub(condition: isPath("/rest/v1.1/me/sites") && isMethodPOST()) { _ in
            HTTPStubsResponse(jsonObject: [String: Any](), statusCode: 200, headers: nil)
        }

        let account = try createAccount(withUsername: "username", authToken: "token")
        accountService.setDefaultWordPressComAccount(account)

        contextManager.performAndSave { context in
            WPAccount.lookup(withObjectID: account.objectID, in: context)?
                .addBlogs(self.createMockBlogs(withIDs: [1, 2, 3, 4, 5, 6], in: context))
        }

        let blog = try XCTUnwrap(Blog.lookup(withID: 1, in: mainContext))
        XCTAssertTrue(blog.visible)
        self.accountService.setVisibility(false, forBlogs: [blog])
        expect(blog.visible).toEventually(beFalse())
    }

}
