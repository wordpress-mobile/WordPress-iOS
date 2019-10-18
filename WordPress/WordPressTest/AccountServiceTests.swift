import UIKit
import XCTest
@testable import WordPress

class AccountServiceTests: XCTestCase {
    var contextManager: TestContextManager!
    var accountService: AccountService!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        contextManager.requiresTestExpectation = false
        accountService = AccountService(managedObjectContext: contextManager.mainContext)
    }

    override func tearDown() {
        super.tearDown()

        deleteTestAccounts()

        ContextManager.overrideSharedInstance(nil)
        contextManager.mainContext.reset()
        contextManager = nil
        accountService = nil
    }

    func deleteTestAccounts() {
        let context = contextManager.mainContext
        for account in accountService.allAccounts() {
            context.delete(account)
        }
        contextManager.save(context)
    }

    func testCreateWordPressComAccountUUID() {
        let account = accountService.createOrUpdateAccount(withUsername: "username", authToken: "authtoken")
        XCTAssertNotNil(account.uuid, "UUID should be set")
    }

    func testSetDefaultWordPressComAccountCheckUUID() {
        let account = accountService.createOrUpdateAccount(withUsername: "username", authToken: "authtoken")

        accountService.setDefaultWordPressComAccount(account)

        let uuid = UserDefaults.standard.string(forKey: "AccountDefaultDotcomUUID")
        XCTAssertNotNil(uuid, "Default UUID should be set")
        XCTAssertEqual(uuid!, account.uuid, "UUID should be set as default")
    }

    func testGetDefaultWordPressComAccountNoneSet() {
        XCTAssertNil(accountService.defaultWordPressComAccount(), "No default account should be set")
    }

    func testGetDefaultWordPressComAccount() {
        let account = accountService.createOrUpdateAccount(withUsername: "username", authToken: "authtoken")

        accountService.setDefaultWordPressComAccount(account)

        let defaultAccount = accountService.defaultWordPressComAccount()
        XCTAssertNotNil(defaultAccount, "Default account should be set")
        XCTAssertEqual(defaultAccount, account, "Default account should the one created")
    }

    func testNumberOfAccountsNoAccounts() {
        XCTAssertTrue(0 == accountService.numberOfAccounts(), "There should be zero accounts")
    }

    func testNumberOfAccountsOneAccount() {
        _ = accountService.createOrUpdateAccount(withUsername: "username", authToken: "authtoken")

        XCTAssertTrue(1 == accountService.numberOfAccounts(), "There should be one account")
    }

    func testNumberOfAccountsTwoAccounts() {
        _ = accountService.createOrUpdateAccount(withUsername: "username", authToken: "authtoken")
        _ = accountService.createOrUpdateAccount(withUsername: "username2", authToken: "authtoken2")

        XCTAssertTrue(2 == accountService.numberOfAccounts(), "There should be two accounts")
    }

    func testRemoveDefaultWordPressComAccountNoAccount() {
        accountService.removeDefaultWordPressComAccount()

        XCTAssertTrue(true, "Test passes if no exception thrown")
    }

    func testRemoveDefaultWordPressComAccountAccountSet() {
        accountService.removeDefaultWordPressComAccount()

        let account = accountService.createOrUpdateAccount(withUsername: "username", authToken: "authtoken")

        accountService.setDefaultWordPressComAccount(account)


        accountService.removeDefaultWordPressComAccount()

        XCTAssertNil(accountService.defaultWordPressComAccount(), "No default account should be set")
        XCTAssertTrue(account.isFault, "Account should be deleted")
    }

    func testCreateAccountSetsDefaultAccount() {
        XCTAssertNil(accountService.defaultWordPressComAccount())

        let account = accountService.createOrUpdateAccount(withUsername: "username", authToken: "authtoken")
        XCTAssertEqual(accountService.defaultWordPressComAccount(), account)
    }

    func testCreateAccountDoesntReplaceDefaultAccount() {
        XCTAssertNil(accountService.defaultWordPressComAccount())

        let account = accountService.createOrUpdateAccount(withUsername: "username", authToken: "authtoken")
        XCTAssertEqual(accountService.defaultWordPressComAccount(), account)

        _ = accountService.createOrUpdateAccount(withUsername: "another", authToken: "authtoken")
        XCTAssertEqual(accountService.defaultWordPressComAccount(), account)
    }

    func testRestoreDefaultAccount() {
        XCTAssertNil(accountService.defaultWordPressComAccount())

        let account = accountService.createOrUpdateAccount(withUsername: "username", authToken: "authtoken")
        XCTAssertEqual(accountService.defaultWordPressComAccount(), account)

        UserDefaults.standard.removeObject(forKey: "AccountDefaultDotcomUUID")

        accountService.restoreDisassociatedAccountIfNecessary()
        XCTAssertEqual(accountService.defaultWordPressComAccount(), account)
    }

    func testAccountUsedForJetpackIsNotRestored() {
        XCTAssertNil(accountService.defaultWordPressComAccount())

        let account = accountService.createOrUpdateAccount(withUsername: "username", authToken: "authtoken")
        XCTAssertEqual(accountService.defaultWordPressComAccount(), account)

        let context = contextManager.mainContext
        let jetpackAccount = accountService.createOrUpdateAccount(withUsername: "jetpack", authToken: "jetpack")
        let blog = Blog(context: context)
        blog.xmlrpc = "http://test.blog/xmlrpc.php"
        blog.username = "admin"
        blog.url = "http://test.blog/"
        blog.isHostedAtWPcom = false
        blog.account = jetpackAccount
        contextManager.save(context)

        UserDefaults.standard.removeObject(forKey: "AccountDefaultDotcomUUID")
        accountService.restoreDisassociatedAccountIfNecessary()
        XCTAssertEqual(accountService.defaultWordPressComAccount(), account)

        accountService.removeDefaultWordPressComAccount()
        XCTAssertNil(accountService.defaultWordPressComAccount())
    }

    func testMergeMultipleDuplicateAccounts() {
        let context = contextManager.mainContext
        let account1 = WPAccount(context: context)
        account1.userID = 1
        account1.username = "username"
        account1.authToken = "authToken"
        account1.uuid = UUID().uuidString

        let account2 = WPAccount(context: context)
        account2.userID = 1
        account2.username = "username"
        account2.authToken = "authToken"
        account2.uuid = UUID().uuidString

        let account3 = WPAccount(context: context)
        account3.userID = 1
        account3.username = "username"
        account3.authToken = "authToken"
        account3.uuid = UUID().uuidString


        account1.addBlogs(createMockBlogs(withIDs: [1, 2, 3, 4, 5, 6], in: context))
        account2.addBlogs(createMockBlogs(withIDs: [1, 2, 3], in: context))
        account3.addBlogs(createMockBlogs(withIDs: [4, 5, 6], in: context))
        contextManager.save(context)

        accountService.setDefaultWordPressComAccount(account1)

        accountService.mergeDuplicatesIfNecessary()
        contextManager.save(context)

        XCTAssertFalse(account1.isDeleted)
        XCTAssertTrue(account2.isDeleted)
        XCTAssertTrue(account3.isDeleted)

        let service = BlogService(managedObjectContext: contextManager.mainContext)
        let blogs = service.blogsForAllAccounts()
        XCTAssertTrue(blogs.count == 6)
        XCTAssertTrue(account1.blogs.count == 6)
    }

    func testMergeDuplicateAccountsKeepingNonDups() {
        let context = contextManager.mainContext
        let account1 = WPAccount(context: context)
        account1.userID = 1
        account1.username = "username"
        account1.authToken = "authToken"
        account1.uuid = UUID().uuidString

        let account2 = WPAccount(context: context)
        account2.userID = 1
        account2.username = "username"
        account2.authToken = "authToken"
        account2.uuid = UUID().uuidString

        let account3 = WPAccount(context: context)
        account3.userID = 3
        account3.username = "username3"
        account3.authToken = "authToken3"
        account3.uuid = UUID().uuidString

        account1.addBlogs(createMockBlogs(withIDs: [1, 2, 3, 4, 5, 6], in: context))
        account2.addBlogs(createMockBlogs(withIDs: [1, 2, 3], in: context))
        account3.addBlogs(createMockBlogs(withIDs: [4, 5, 6], in: context))
        contextManager.save(context)
        accountService.setDefaultWordPressComAccount(account1)

        accountService.mergeDuplicatesIfNecessary()
        contextManager.save(context)

        XCTAssertFalse(account1.isDeleted)
        XCTAssertTrue(account2.isDeleted)
        XCTAssertFalse(account3.isDeleted)
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

}
