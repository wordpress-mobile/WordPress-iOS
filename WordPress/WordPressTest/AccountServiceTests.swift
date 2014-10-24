import UIKit
import XCTest

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
        let account = accountService.createOrUpdateWordPressComAccountWithUsername("username", password: "password", authToken: "authtoken")
        XCTAssertNotNil(account.uuid, "UUID should be set")
    }
    
    func testCreateSelfHostedAccountUUID() {
        let account = accountService.createOrUpdateSelfHostedAccountWithXmlrpc("http://example.com/xmlrpc.php", username: "username", andPassword: "password")
        XCTAssertNotNil(account.uuid, "UUID should be set")
    }
    
    func testSetDefaultWordPressComAccountCheckUUID() {
        let account = accountService.createOrUpdateWordPressComAccountWithUsername("username", password: "password", authToken: "authtoken")
        
        accountService.setDefaultWordPressComAccount(account)
        
        let uuid = NSUserDefaults.standardUserDefaults().stringForKey("AccountDefaultDotcomUUID")
        XCTAssertNotNil(uuid, "Default UUID should be set")
        XCTAssertEqual(uuid!, account.uuid, "UUID should be set as default")
    }

    func testGetDefaultWordPressComAccountNoneSet() {
        XCTAssertNil(accountService.defaultWordPressComAccount(), "No default account should be set")
    }
    
    func testGetDefaultWordPressComAccount() {
        let account = accountService.createOrUpdateWordPressComAccountWithUsername("username", password: "password", authToken: "authtoken")
        
        accountService.setDefaultWordPressComAccount(account)
        
        let defaultAccount = accountService.defaultWordPressComAccount()
        XCTAssertNotNil(defaultAccount, "Default account should be set")
        XCTAssertEqual(defaultAccount, account, "Default account should the one created")
    }
}
