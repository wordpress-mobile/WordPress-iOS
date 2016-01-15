import UIKit
import RxSwift
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

    func testDefaultAccountObjectIDEmitsInitialValue() {
        let currentObjectID = waitForValueIn(accountService.defaultAccountObjectID, block: {})

        XCTAssertNil(currentObjectID)
    }

    func testDefaultAccountObjectIDEmitsValueWhenAccountIsSet() {
        var createdAccount: WPAccount? = nil
        let currentObjectID = waitForValueIn(accountService.defaultAccountObjectID, skip: 1) { [unowned self] in
            createdAccount = self.accountService.createOrUpdateAccountWithUsername("username", authToken: "authtoken")
        }
        guard let account = createdAccount else {
            XCTFail("account should not be nil")
            return
        }

        XCTAssertEqual(currentObjectID, account.objectID)
    }

    func testDefaultAccountObjectIDEmitsValueWhenAccointIsRemoved() {
        let currentObjectID = waitForValueIn(accountService.defaultAccountObjectID, skip: 2) { [unowned self] in
            self.accountService.createOrUpdateAccountWithUsername("username", authToken: "authtoken")
            self.accountService.removeDefaultWordPressComAccount()
        }
        XCTAssertNil(currentObjectID)
    }

    func testDefaultAccountChangedEmitsInitialValue() {
        let value = waitForValueIn(accountService.defaultAccountChanged, block: {})

        XCTAssertNil(value)
    }

    func testDefaultAccountChangedEmitsValueWhenPropertyIsChanged() {
        let value = waitForValueIn(accountService.defaultAccountChanged, skip: 2) { [unowned self] in
            // Emits initial nil (1)
            // Emits account (2)
            let account = self.accountService.createOrUpdateAccountWithUsername("jack", authToken: "authtoken")

            // Emits account (3)
            account.email = "jack@sparrow.com"
            self.contextManager.saveContextAndWait(self.accountService.managedObjectContext)
        }

        XCTAssertNotNil(value)
        XCTAssertEqual(value?.email, "jack@sparrow.com")
        XCTAssertNil(value?.displayName)
    }

    func testDefaultAccountChangedEmitsValueWhenPropertyIsChangedAfterAnotherAccountChanges() {
        let value = waitForValueIn(accountService.defaultAccountChanged, skip: 3) { [unowned self] in
            // Emits initial nil (1)
            // Emits account (2)
            let account = self.accountService.createOrUpdateAccountWithUsername("jack", authToken: "authtoken")

            // Emits account (3)
            account.email = "jack@sparrow.com"
            self.contextManager.saveContextAndWait(self.accountService.managedObjectContext)

            // Doesn't emit (3)
            let another = self.accountService.createOrUpdateAccountWithUsername("elizabeth", authToken: "authtoken2")
            another.displayName = "Elizabeth Swann"
            self.contextManager.saveContextAndWait(self.accountService.managedObjectContext)

            // Emits account (4)
            account.displayName = "Jack Sparrow"
            self.contextManager.saveContextAndWait(self.accountService.managedObjectContext)
        }

        XCTAssertNotNil(value)
        XCTAssertEqual(value?.email, "jack@sparrow.com")
        XCTAssertEqual(value?.displayName, "Jack Sparrow")
    }

    func testDefaultAccountChangedEmitsValueAfterAccountIsRemoved() {
        let value = waitForValueIn(accountService.defaultAccountChanged, skip: 2) { [unowned self] in
            // Emits initial nil (1)
            // Emits account (2)
            self.accountService.createOrUpdateAccountWithUsername("jack", authToken: "authtoken")

            // Emits nil (3)
            self.accountService.removeDefaultWordPressComAccount()
        }

        XCTAssertNil(value)
    }

    private func waitForValueIn<T>(observable: Observable<T>, skip: Int = 0, block: () -> Void) -> T {
        var result: T? = nil
        let expectation = expectationWithDescription("Observable completed \(observable)")
        let subscription = observable.skip(skip).take(1).subscribe { (event) -> Void in
            switch event {
            case .Next(let value):
                result = value
            case .Error(let error):
                XCTFail("Observable emitted error \(error)")
            case .Completed:
                expectation.fulfill()
            }
        }

        block()

        waitForExpectationsWithTimeout(5) { _ in
            subscription.dispose()
        }
        return result!
    }
}
