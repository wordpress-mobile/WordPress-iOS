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

    class ImageServiceMock: ImageServing {
        var capturedAccountToken: String = ""
        var capturedAccountEmail: String = ""

        func uploadImage(_ image: UIImage, accountEmail: String, accountToken: String) async throws -> URLResponse {
            capturedAccountEmail = accountEmail
            capturedAccountToken = accountToken
            return URLResponse()
        }

        func uploadImage(_ image: UIImage, accountEmail: String, accountToken: String, completion: ((NSError?) -> Void)?) {
            capturedAccountEmail = accountEmail
            capturedAccountToken = accountToken
        }

        func fetchImage(with email: String, options: Gravatar.GravatarImageDownloadOptions, completionHandler: Gravatar.ImageDownloadCompletion?) -> Gravatar.CancellableDataTask {
            fatalError("Not implemented")
        }

        func fetchImage(with url: URL, forceRefresh: Bool, processor: Gravatar.ImageProcessor, completionHandler: Gravatar.ImageDownloadCompletion?) -> Gravatar.CancellableDataTask? {
            fatalError("Not implemented")
        }

        func fetchImage(with email: String, options: Gravatar.GravatarImageDownloadOptions) async throws -> Gravatar.GravatarImageDownloadResult {
            fatalError("Not implemented")
        }

        func fetchImage(with url: URL, forceRefresh: Bool, processor: Gravatar.ImageProcessor) async throws -> Gravatar.GravatarImageDownloadResult {
            fatalError("Not implemented")
        }
    }

    class GravatarServiceTester: GravatarService {
        var gravatarServiceRemoteMock: ImageServiceMock?

        override func gravatarImageService() -> ImageServing {
            gravatarServiceRemoteMock = ImageServiceMock()
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
