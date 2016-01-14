import XCTest
import RxSwift
@testable import WordPress

/* @koke 2016-01-14

 These are in a separate test case to avoid a problem with asynchronous testing
 and notifications.
 
 In the current implementation, `-[AccountService setDefaultAccount:]` posts the
 account changed notification using `dispatch_async` on the main queue. This
 meant that if a specific test set the default account but didn't explicitly set
 an expectation to receive the notification, it would get posted when a
 different test was running.

 In practice, this meant that `testCreateAccountDoesntReplaceDefaultAccount`
 would set the default account and enqueue a block to post the notification.
 More tests would run before this block until `testDefaultAccountChanged` would
 wait for a notification, getting the account changed notifications for all the
 previous tests.

 Since you can only fulfill an expectation once, the test would crash on the
 second notification. Even without crashing, the test would be waiting for the
 wrong notification.

 I have my doubts about this being a XCTest bug, or just an edge case. It didn't
 make much sense to force all the other AccountService tests to clean up
 notifications, so I moved this to a separate test case, and it seems to have
 fixed the problem. Maybe XCTest gives a bit more time to GCD to run the pending
 blocks between test cases.

*/
class AccountServiceRxTests: XCTestCase {
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
