import Foundation
import XCTest
import WordPressKit
@testable import WordPress


/// GravatarService Unit Tests
///
class GravatarServiceTests: XCTestCase {
    class GravatarServiceRemoteMock: GravatarServiceRemote {
        var capturedAccountToken: String = ""
        var capturedAccountEmail: String = ""

        override func uploadImage(_ image: UIImage, accountEmail: String, accountToken: String, completion: ((NSError?) -> ())?) {
            capturedAccountEmail = accountEmail
            capturedAccountToken = accountToken

            if let completion = completion {
                completion(nil)
            }
        }

    }

    class GravatarServiceTester: GravatarService {
        var gravatarServiceRemoteMock: GravatarServiceRemoteMock?

        override func gravatarServiceRemote() -> GravatarServiceRemote {
            gravatarServiceRemoteMock = GravatarServiceRemoteMock()
            return gravatarServiceRemoteMock!
        }
    }

    private var contextManager: TestContextManager!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
    }

    override func tearDown() {
        super.tearDown()
        ContextManager.overrideSharedInstance(nil)
    }

    func testServiceSanitizesEmailAddressCapitals() {
        let account = createTestAccount(username: "some", token: "1234", emailAddress: "emAil@wordpress.com")

        let gravatarService = GravatarServiceTester()
        gravatarService.uploadImage(UIImage(), forAccount: account)

        XCTAssertEqual("email@wordpress.com", gravatarService.gravatarServiceRemoteMock!.capturedAccountEmail)
    }

    func testServiceSanitizesEmailAddressTrimsSpaces() {
        let account = createTestAccount(username: "some", token: "1234", emailAddress: " email@wordpress.com ")

        let gravatarService = GravatarServiceTester()
        gravatarService.uploadImage(UIImage(), forAccount: account)

        XCTAssertEqual("email@wordpress.com", gravatarService.gravatarServiceRemoteMock!.capturedAccountEmail)
    }

    private func createTestAccount(username: String, token: String, emailAddress: String) -> WPAccount {
        let mainContext = contextManager.mainContext

        let accountService = AccountService(managedObjectContext: mainContext)
        let defaultAccount = accountService.createOrUpdateAccount(withUsername: username, authToken: token)
        defaultAccount.email = emailAddress
        contextManager.saveContextAndWait(mainContext)

        accountService.setDefaultWordPressComAccount(defaultAccount)
        XCTAssertNotNil(accountService.defaultWordPressComAccount())

        return defaultAccount
    }
}
