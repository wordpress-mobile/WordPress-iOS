import UIKit
import XCTest
@testable import WordPress

class AccountServiceTests: XCTestCase {
    var contextManager: TestContextManager!
    var accountService: AccountService!

    override func setUp() {
        super.setUp()
        
        contextManager = TestContextManager()
        accountService = AccountService(managedObjectContext: contextManager.mainContext)!
    }
    
    override func tearDown() {
        super.tearDown()
        
        contextManager = nil
        accountService = nil
    }

    func testCreateWordPressComAccountUUID() {
        let account = accountService.createOrUpdateAccountWithUsername("username", authToken: "authtoken")
        XCTAssertNotNil(account.uuid, "UUID should be set")
    }
    
    func testSetDefaultWordPressComAccountCheckUUID() {
        let account = accountService.createOrUpdateAccountWithUsername("username", authToken: "authtoken")
        
        accountService.setDefaultWordPressComAccount(account)
        
        let uuid = NSUserDefaults.standardUserDefaults().stringForKey("AccountDefaultDotcomUUID")
        XCTAssertNotNil(uuid, "Default UUID should be set")
        XCTAssertEqual(uuid!, account.uuid, "UUID should be set as default")
    }

    func testGetDefaultWordPressComAccountNoneSet() {
        XCTAssertNil(accountService.defaultWordPressComAccount(), "No default account should be set")
    }
    
    func testGetDefaultWordPressComAccount() {
        let account = accountService.createOrUpdateAccountWithUsername("username", authToken: "authtoken")
        
        accountService.setDefaultWordPressComAccount(account)
        
        let defaultAccount = accountService.defaultWordPressComAccount()
        XCTAssertNotNil(defaultAccount, "Default account should be set")
        XCTAssertEqual(defaultAccount, account, "Default account should the one created")
    }
    
    func testNumberOfAccountsNoAccounts() {
        XCTAssertTrue(0 == accountService.numberOfAccounts(), "There should be zero accounts")
    }
    
    func testNumberOfAccountsOneAccount() {
        _ = accountService.createOrUpdateAccountWithUsername("username", authToken: "authtoken")
        
        XCTAssertTrue(1 == accountService.numberOfAccounts(), "There should be one account")
    }
    
    func testNumberOfAccountsTwoAccounts() {
        _ = accountService.createOrUpdateAccountWithUsername("username", authToken: "authtoken")
        _ = accountService.createOrUpdateAccountWithUsername("username2", authToken: "authtoken2")
        
        XCTAssertTrue(2 == accountService.numberOfAccounts(), "There should be two accounts")
    }
    
    func testRemoveDefaultWordPressComAccountNoAccount() {
        accountService.removeDefaultWordPressComAccount()
        
        XCTAssertTrue(true, "Test passes if no exception thrown")
    }
    
    func testRemoveDefaultWordPressComAccountAccountSet() {
        accountService.removeDefaultWordPressComAccount()
        
        let account = accountService.createOrUpdateAccountWithUsername("username", authToken: "authtoken")
        
        accountService.setDefaultWordPressComAccount(account)
        
        
        accountService.removeDefaultWordPressComAccount()
        
        XCTAssertNil(accountService.defaultWordPressComAccount(), "No default account should be set")
        XCTAssertTrue(account.fault, "Account should be deleted")
    }

    func testCreateAccountSetsDefaultAccount() {
        XCTAssertNil(accountService.defaultWordPressComAccount())

        let account = accountService.createOrUpdateAccountWithUsername("username", authToken: "authtoken")
        XCTAssertEqual(accountService.defaultWordPressComAccount(), account)
    }

    func testCreateAccountDoesntReplaceDefaultAccount() {
        XCTAssertNil(accountService.defaultWordPressComAccount())

        let account = accountService.createOrUpdateAccountWithUsername("username", authToken: "authtoken")
        XCTAssertEqual(accountService.defaultWordPressComAccount(), account)

        accountService.createOrUpdateAccountWithUsername("another", authToken: "authtoken")
        XCTAssertEqual(accountService.defaultWordPressComAccount(), account)
    }

    func testDefaultAccountObjectID() {
        var currentObjectID: NSManagedObjectID? = nil
        var eventCount = 0
        let subscription = accountService.defaultAccountObjectID.subscribeNext { objectID in
            currentObjectID = objectID
            eventCount += 1
        }
        defer {
            subscription.dispose()
        }

        // The observable should emit an initial value on subscription
        XCTAssertEqual(eventCount, 1)
        XCTAssertNil(currentObjectID)

        // The account changed notification is currently posted with a dispatch_async
        // so we need to add a bit of boilerplate to wait for it
        var createdAccount: WPAccount? = nil
        expectNotification(WPAccountDefaultWordPressComAccountChangedNotification) {
            createdAccount = self.accountService.createOrUpdateAccountWithUsername("username", authToken: "authtoken")
        }
        guard let account = createdAccount else {
            XCTFail("account should not be nil")
            return
        }

        XCTAssertEqual(eventCount, 2)
        XCTAssertEqual(currentObjectID, account.objectID)

        accountService.removeDefaultWordPressComAccount()
        XCTAssertEqual(currentObjectID, nil)
        XCTAssertEqual(eventCount, 3)
    }

    func testDefaultAccountChanged() {
        var currentAccount: WPAccount? = nil
        var eventCount = 0
        let subscription = accountService.defaultAccountChanged.subscribeNext { account in
            currentAccount = account
            eventCount += 1
        }
        defer {
            subscription.dispose()
        }

        // 1. Emit an initial value on subscription
        XCTAssertEqual(eventCount, 1)
        XCTAssertNil(currentAccount)

        // The account changed notification is currently posted with a dispatch_async
        // so we need to add a bit of boilerplate to wait for it
        var createdAccount: WPAccount? = nil
        expectNotification(WPAccountDefaultWordPressComAccountChangedNotification) {
            createdAccount = self.accountService.createOrUpdateAccountWithUsername("username", authToken: "authtoken")
        }
        guard let account = createdAccount else {
            XCTFail("account should not be nil")
            return
        }

        // 2. Emit value when account is set
        XCTAssertEqual(eventCount, 2)
        XCTAssertEqual(currentAccount, account)

        // 3. Emit value when a property changes
        let email = "username@example.com"
        account.email = email
        contextManager.saveContextAndWait(accountService.managedObjectContext)

        XCTAssertEqual(eventCount, 3)
        XCTAssertEqual(currentAccount, account)
        XCTAssertEqual(currentAccount?.email, email)

        // 4. Don't emit value when another account changes
        let secondAccount = accountService.createOrUpdateAccountWithUsername("username2", authToken: "authtoken")
        secondAccount.email = "another@example.com"
        contextManager.saveContextAndWait(accountService.managedObjectContext)

        XCTAssertEqual(eventCount, 3)
        XCTAssertEqual(currentAccount, account)
        XCTAssertEqual(currentAccount?.email, email)

        // 5. Emit value when another propery changes
        let displayName = "Jack Sparrow"
        account.displayName = displayName
        contextManager.saveContextAndWait(accountService.managedObjectContext)

        XCTAssertEqual(eventCount, 4)
        XCTAssertEqual(currentAccount, account)
        XCTAssertEqual(currentAccount?.displayName, displayName)

        // 6. Emit value when account is removed
        accountService.removeDefaultWordPressComAccount()

        XCTAssertEqual(eventCount, 5)
        XCTAssertNil(currentAccount)
    }
}
