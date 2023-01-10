import Foundation
import XCTest
import WordPressKit
@testable import WordPress


/// GravatarService Unit Tests
///
class GravatarServiceTests: CoreDataTestCase {
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

        let accountService = AccountService(coreDataStack: contextManager)
        let accountId = accountService.createOrUpdateAccount(withUsername: username, authToken: token)
        let defaultAccount = try! contextManager.mainContext.existingObject(with: accountId) as! WPAccount
        defaultAccount.email = emailAddress
        contextManager.saveContextAndWait(mainContext)

        accountService.setDefaultWordPressComAccount(defaultAccount)
        XCTAssertNotNil(try WPAccount.lookupDefaultWordPressComAccount(in: mainContext))

        return defaultAccount
    }
}
