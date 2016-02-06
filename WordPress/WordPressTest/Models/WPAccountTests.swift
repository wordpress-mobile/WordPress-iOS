import XCTest

class WPAccountTests: XCTestCase {
    private let accountEntityName = "Account"
    private let oneHundredYearsInMilliseconds: NSTimeInterval = 1000 * 60 * 60 * 24 * 7 * 52 * 100

    private var account: WPAccount!
    
    override func setUp() {
        super.setUp()
        
        let context = TestContextManager.sharedInstance().mainContext
        account = NSEntityDescription.insertNewObjectForEntityForName(accountEntityName, inManagedObjectContext: context) as! WPAccount
    }
    
    override func tearDown() {
        account = nil
        
        super.tearDown()
    }
    
    func testWasCreatedBeforeHideViewAdminDateBeforeDate() {
        let beforeDate = NSDate(timeIntervalSince1970: 0)
        account.date = beforeDate
        
        XCTAssertTrue(account.wasCreatedBeforeHideViewAdminDate(), "Should return false as date is before 09-07-2015")
    }
    
    func testWasCreatedBeforeHideViewAdminDateAfterDate() {
        let afterDate = NSDate(timeIntervalSince1970: oneHundredYearsInMilliseconds)
        account.date = afterDate
        
        XCTAssertFalse(account.wasCreatedBeforeHideViewAdminDate(), "Should return false as date is after 09-07-2015")
    }
}
