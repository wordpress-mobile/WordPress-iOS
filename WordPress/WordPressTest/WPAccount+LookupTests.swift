import XCTest
@testable import WordPress

class WPAccountLookupTests: CoreDataTestCase {

    func testIsDefaultWordPressComAccountIsFalseWhenNoAccountIsSet() {
        UserSettings.defaultDotComUUID = nil
        let account = makeAccount()
        XCTAssertFalse(account.isDefaultWordPressComAccount)
    }

    func testIsDefaultWordPressComAccountIsTrueWhenUUIDMatches() {
        let account = makeAccount()
        UserSettings.defaultDotComUUID = account.uuid
        XCTAssertTrue(account.isDefaultWordPressComAccount)
    }

    func testHasBlogsReturnsFalseWhenNoBlogsArePresentForAccount() {
        let account = makeAccount()
        XCTAssertFalse(account.hasBlogs)
    }

    func testHasBlogsReturnsTrueWhenBlogsArePresentForAccount() {
        let blog = BlogBuilder(contextManager.mainContext)
            .withAnAccount()
            .build()
        XCTAssertTrue(blog.account!.hasBlogs)
    }

    func testLookupDefaultWordPressComAccountReturnsNilWhenNoAccountIsSet() throws {
        makeAccount()
        try XCTAssertNil(WPAccount.lookupDefaultWordPressComAccount(in: contextManager.mainContext))
    }

    func testLookupDefaultWordPressComAccountReturnsAccount() throws {
        let account = makeAccount()
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
        makeAccount()
        try XCTAssertNil(WPAccount.lookup(withUUIDString: "", in: contextManager.mainContext))
    }

    func testLookupAccountByUUIDReturnsAccount() throws {
        let uuid = UUID().uuidString
        makeAccount { $0.with(uuid: uuid) }
        try XCTAssertEqual(WPAccount.lookup(withUUIDString: uuid, in: contextManager.mainContext)?.uuid, uuid)
    }

    func testLookupAccountByUsernameReturnsNilIfNotFound() throws {
        makeAccount()
        try XCTAssertNil(WPAccount.lookup(withUsername: "", in: contextManager.mainContext))
    }

    func testLookupAccountByUsernameReturnsAccountForUsername() throws {
        let username = UUID().uuidString
        makeAccount { $0.with(username: username) }
        try XCTAssertEqual(WPAccount.lookup(withUsername: username, in: contextManager.mainContext)?.username, username)
    }

    func testLookupAccountByUsernameReturnsAccountForEmailAddress() throws {
        let email = UUID().uuidString
        makeAccount { $0.with(email: email) }
        try XCTAssertEqual(WPAccount.lookup(withUsername: email, in: contextManager.mainContext)?.email, email)
    }

    func testLookupByUserIdReturnsNilIfNotFound() throws {
        makeAccount { $0.with(id: 1) } // Make a test account that we don't want to match
        try XCTAssertNil(WPAccount.lookup(withUserID: 2, in: contextManager.mainContext))
    }

    func testLookupByUserIdReturnsAccount() throws {
        makeAccount { $0.with(id: 1) }
        try XCTAssertEqual(WPAccount.lookup(withUserID: 1, in: contextManager.mainContext)?.userID, 1)
    }

    func testLookupNumberOfAccountsReturnsZeroByDefault() throws {
        try XCTAssertEqual(WPAccount.lookupNumberOfAccounts(in: contextManager.mainContext), 0)
    }

    func testLookupNumberOfAccountsReturnsCorrectValue() throws {
        makeAccount()
        makeAccount()
        makeAccount()

        try XCTAssertEqual(WPAccount.lookupNumberOfAccounts(in: contextManager.mainContext), 3)
    }

    @discardableResult
    func makeAccount(_ additionalSetup: (AccountBuilder) -> (AccountBuilder) = { $0 }) -> WPAccount {
        additionalSetup(AccountBuilder(contextManager)).build()
    }
}
