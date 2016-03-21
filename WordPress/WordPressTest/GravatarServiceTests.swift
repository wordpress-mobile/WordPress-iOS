import Foundation
import XCTest
import WordPress


/// GravatarService Unit Tests
///
class GravatarServiceTests : XCTestCase
{
    private var contextManager : TestContextManager!
    
    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
    }
    
    func testServiceInitializerFailsWhenMissingDefaultAccount() {
        let mainContext = contextManager.mainContext
        
        let accountService = AccountService(managedObjectContext: mainContext)
        accountService.removeDefaultWordPressComAccount()
        
        let gravatarService = GravatarService(context: mainContext)
        XCTAssertNil(gravatarService)
    }
    
    func testServiceInitializerSucceedsWhenTokenAndMailAreBothValid() {
        let mainContext = contextManager.mainContext
        
        let accountService = AccountService(managedObjectContext: mainContext)
        let defaultAccount = accountService.createOrUpdateAccountWithUsername("some", authToken: "1234")
        defaultAccount.email = "email@wordpress.com"
        contextManager.saveContextAndWait(mainContext)
        
        accountService.setDefaultWordPressComAccount(defaultAccount)
        XCTAssertNotNil(accountService.defaultWordPressComAccount())
        
        let gravatarService = GravatarService(context: mainContext)
        XCTAssertNotNil(gravatarService)
    }
}
