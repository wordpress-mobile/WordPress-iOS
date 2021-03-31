import XCTest
@testable import WordPress

final class WPAccountLookupTests: XCTestCase {

    private var contextManager: TestContextManager!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
    }

    func testIsDefaultWordPressComAccountIsFalseWhenNoAccountIsSet() {
        UserSettings.defaultDotComUUID = nil
        let account = AccountBuilder(contextManager).build()
        XCTAssertFalse(account.isDefaultWordPressComAccount)
    }

    func testIsDefaultWordPressComAccountIsTrueWhenUUIDMatches() {
        let account = AccountBuilder(contextManager).build()
        UserSettings.defaultDotComUUID = account.uuid
        XCTAssertTrue(account.isDefaultWordPressComAccount)
    }

    func testHasBlogsReturnsFalseWhenNoBlogsArePresentForAccount() {
        let account = AccountBuilder(contextManager).build()
        XCTAssertFalse(account.hasBlogs)
    }

    func testHasBlogsReturnsTrueWhenBlogsArePresentForAccount() {
        let blog = BlogBuilder(contextManager.mainContext)
            .withAnAccount()
            .build()
        XCTAssertTrue(blog.account!.hasBlogs)
    }

    func testLookupDefaultWordPressComAccountReturnsNilWhenNoAccountIsSet() throws {
        let _ = AccountBuilder(contextManager).build()
        try XCTAssertNil(WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext))
    }

    func testLookupDefaultWordPressComAccountReturnsAccount() throws {
        let account = AccountBuilder(contextManager).build()
        UserSettings.defaultDotComUUID = account.uuid

        try XCTAssertEqual(WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext)?.uuid, account.uuid)
    }

    /// This is a test for a side effect – that the user setting is deleted by default
    func testLookupDefaultWordPressComAccountMakesDefaultUUIDNilForInvalidValue() throws {
        UserSettings.defaultDotComUUID = ""
        _ = try WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext)
        XCTAssertNil(UserSettings.defaultDotComUUID)
    }

    func testLookupAccountByUUIDReturnsNilForInvalidAccount() throws {
        AccountBuilder(contextManager).build()
        try XCTAssertNil(WPAccount.lookup(withUUIDString: "", in: contextManager.mainContext))
    }

    func testLookupAccountByUUIDReturnsAccount() throws {
        let uuid = UUID().uuidString
        AccountBuilder(contextManager).with(uuid: uuid).build()
        try XCTAssertEqual(WPAccount.lookup(withUUIDString: uuid, in: contextManager.mainContext)?.uuid, uuid)
    }

    func testLookupAccountByUsernameReturnsNilIfNotFound() throws {
        AccountBuilder(contextManager).build()
        try XCTAssertNil(WPAccount.lookup(withUsername: "", in: contextManager.mainContext))
    }

    func testLookupAccountByUsernameReturnsAccountForUsername() throws {
        let username = UUID().uuidString
        AccountBuilder(contextManager).with(username: username).build()
        try XCTAssertEqual(WPAccount.lookup(withUsername: username, in: contextManager.mainContext)?.username, username)
    }

    func testLookupAccountByUsernameReturnsAccountForEmailAddress() throws {
        let email = UUID().uuidString
        AccountBuilder(contextManager).with(email: email).build()
        try XCTAssertEqual(WPAccount.lookup(withUsername: email, in: contextManager.mainContext)?.email, email)
    }

    func testLookupByUserIdReturnsNilIfNotFound() throws {
        AccountBuilder(contextManager).with(id: 1).build() // Make a test account that we don't want to match
        try XCTAssertNil(WPAccount.lookup(withUserID: 2, in: contextManager.mainContext))
    }

    func testLookupByUserIdReturnsAccount() throws {
        AccountBuilder(contextManager).with(id: 1).build()
        try XCTAssertEqual(WPAccount.lookup(withUserID: 1, in: contextManager.mainContext)?.userID, 1)
    }

    func testLookupNumberOfAccountsReturnsZeroByDefault() throws {
        try XCTAssertEqual(WPAccount.lookupNumberOfAccounts(in: contextManager.mainContext), 0)
    }

    func testLookupNumberOfAccountsReturnsCorrectValue() throws {
        let _ = AccountBuilder(contextManager).build()
        let _ = AccountBuilder(contextManager).build()
        let _ = AccountBuilder(contextManager).build()

        try XCTAssertEqual(WPAccount.lookupNumberOfAccounts(in: contextManager.mainContext), 3)
    }
}
