import Foundation
import XCTest
@testable import WordPress


/// GravatarService Unit Tests
///
class GravatarServiceTests: XCTestCase {
    class GravatarServiceRemoteMock: GravatarServiceRemote {
        let capturedAccountToken: String
        let capturedAccountEmail: String

        init(accountToken: String, accountEmail: String) {
            capturedAccountToken = accountToken
            capturedAccountEmail = accountEmail

            super.init()
        }

        override func uploadImage(_ image: UIImage, accountEmail: String, accountToken: String, completion: ((NSError?) -> ())?) {
            if let completion = completion {
                completion(nil)
            }
        }

        func uploadImage(_ image: UIImage, completion: ((_ error: NSError?) -> ())?) {
            uploadImage(image, accountEmail: capturedAccountEmail, accountToken: capturedAccountToken, completion: completion)
        }
    }

    class GravatarServiceTester: GravatarService {
        var gravatarServiceRemoteMock: GravatarServiceRemoteMock?

        override func gravatarServiceRemoteForAccountToken(accountToken: String, andAccountEmail accountEmail: String) -> GravatarServiceRemote {
            gravatarServiceRemoteMock = GravatarServiceRemoteMock(accountToken: accountToken, accountEmail: accountEmail)
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

    func testServiceInitializerFailsWhenMissingDefaultAccount() {
        let mainContext = contextManager.mainContext

        let accountService = AccountService(managedObjectContext: mainContext)
        accountService.removeDefaultWordPressComAccount()

        let gravatarService = GravatarService(context: mainContext)
        XCTAssertNil(gravatarService)
    }

    func testServiceInitializerSucceedsWhenTokenAndMailAreBothValid() {
        createTestAccount(username: "some", token: "1234", emailAddress: "email@wordpress.com")

        let mainContext = contextManager.mainContext
        let gravatarService = GravatarService(context: mainContext)
        XCTAssertNotNil(gravatarService)
    }

    func testServiceInitializerSanitizesEmailAddressCapitals() {
        createTestAccount(username: "some", token: "1234", emailAddress: "emAil@wordpress.com")

        let mainContext = contextManager.mainContext
        let gravatarService = GravatarServiceTester(context: mainContext)
        gravatarService?.uploadImage(UIImage())

        XCTAssertEqual("email@wordpress.com", gravatarService!.gravatarServiceRemoteMock!.capturedAccountEmail)
    }

    func testServiceInitializerSanitizesEmailAddressTrimsSpaces() {
        createTestAccount(username: "some", token: "1234", emailAddress: " email@wordpress.com ")

        let mainContext = contextManager.mainContext
        let gravatarService = GravatarServiceTester(context: mainContext)
        gravatarService?.uploadImage(UIImage())

        XCTAssertEqual("email@wordpress.com", gravatarService!.gravatarServiceRemoteMock!.capturedAccountEmail)
    }

    private func createTestAccount(username: String, token: String, emailAddress: String) {
        let mainContext = contextManager.mainContext

        let accountService = AccountService(managedObjectContext: mainContext)
        let defaultAccount = accountService.createOrUpdateAccount(withUsername: username, authToken: token)
        defaultAccount.email = emailAddress
        contextManager.saveContextAndWait(mainContext)

        accountService.setDefaultWordPressComAccount(defaultAccount)
        XCTAssertNotNil(accountService.defaultWordPressComAccount())
    }
}
