import UIKit
import XCTest
@testable import WordPress

class AccountServiceTests: XCTestCase {
    var contextManager: TestContextManager!
    var accountService: AccountService!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        accountService = AccountService(managedObjectContext: contextManager.mainContext)
    }

    override func tearDown() {
        super.tearDown()

        ContextManager.overrideSharedInstance(nil)
        contextManager.mainContext.reset()
        contextManager = nil
        accountService = nil
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

}
