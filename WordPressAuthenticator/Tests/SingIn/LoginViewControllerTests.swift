@testable import WordPressAuthenticator
import XCTest

class LoginViewControllerTests: XCTestCase {

    // showSignupEpilogue with loginFields.meta.appleUser set will pass SocialService.apple to
    // the delegate
    func testShowingSignupEpilogueWithGoogleUser() throws {
        WordPressAuthenticator.initializeForTesting()
        let delegateSpy = WordPressAuthenticatorDelegateSpy()
        WordPressAuthenticator.shared.delegate = delegateSpy

        // This might be unnecessary because delegateSpy should be deallocated once the test method finished.
        // Leaving it here, just in case.
        addTeardownBlock {
            WordPressAuthenticator.shared.delegate = nil
        }

        let sut = LoginViewController()
        // We need to embed the SUT in a navigation controller because it expects its
        // navigationController property to not be nil.
        _ = UINavigationController(rootViewController: sut)

        sut.loginFields.meta.socialUser = SocialUser(email: "test@email.com", fullName: "Full Name", service: .google)

        sut.showSignupEpilogue(for: AuthenticatorCredentials())

        let service = try XCTUnwrap(delegateSpy.socialUser?.service)
        guard case .google = service else {
            return XCTFail("Expected Google social service, got \(service) instead")
        }
    }
}
