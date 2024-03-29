import Foundation
import XCTest
import WordPressKit
import Gravatar
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

    class ImageServiceMock: GravatarImageUploader {
        var capturedAccountToken: String = ""
        var capturedAccountEmail: String = ""
        func upload(_ image: UIImage, email: Email, accessToken: String) async throws -> URLResponse {
            capturedAccountEmail = email.rawValue
            capturedAccountToken = accessToken
            return URLResponse()
        }
    }

    func testServiceSanitizesEmailAddressCapitals() {
        let expectation = expectation(description: "uploadImage must invoke completion")
        let account = createTestAccount(username: "some", token: "1234", emailAddress: "emAil@wordpress.com")

        let gravatarService = GravatarService(imageUploader: ImageServiceMock())
        gravatarService.uploadImage(UIImage(), forAccount: account) { _ in
            XCTAssertEqual("email@wordpress.com", (gravatarService.imageUploader as? ImageServiceMock)?.capturedAccountEmail)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testServiceSanitizesEmailAddressTrimsSpaces() {
        let expectation = expectation(description: "uploadImage must invoke completion")
        let account = createTestAccount(username: "some", token: "1234", emailAddress: " email@wordpress.com ")

        let gravatarService = GravatarService(imageUploader: ImageServiceMock())
        gravatarService.uploadImage(UIImage(), forAccount: account) { _ in
            XCTAssertEqual("email@wordpress.com", (gravatarService.imageUploader as? ImageServiceMock)?.capturedAccountEmail)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
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
