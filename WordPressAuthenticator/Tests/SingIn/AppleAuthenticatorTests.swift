import AuthenticationServices
@testable import WordPressAuthenticator
import XCTest

class AppleAuthenticatorTests: XCTestCase {

    // showSignupEpilogue with loginFields.meta.appleUser set will pass SocialService.apple to the delegate
    func testShowingSignupEpilogueWithApple() throws {
        WordPressAuthenticator.initializeForTesting()
        let delegateSpy = WordPressAuthenticatorDelegateSpy()
        WordPressAuthenticator.shared.delegate = delegateSpy

        // This might be unnecessary because delegateSpy should be deallocated once the test method finished.
        // Leaving it here, just in case.
        addTeardownBlock {
            WordPressAuthenticator.shared.delegate = nil
        }

        let socialUserCreatingStub = SocialUserCreatingStub(appleResult: .success((true, true, true, "a", "b")))
        let sut = AppleAuthenticator(signupService: socialUserCreatingStub)

        // Before acting on the SUT, we need to ensure the login fields are set as we expect
        let presenterViewController = UIViewController()
        // We need to create this because it's accessed by showFrom(viewController:)
        _ = UINavigationController(rootViewController: presenterViewController)
        sut.showFrom(viewController: presenterViewController)
        sut.createWordPressComUser(
            appleUserId: "apple-user-id",
            email: "test@email.com",
            name: "Full Name",
            token: "abcd"
        )

        sut.showSignupEpilogue(for: AuthenticatorCredentials())

        let service = try XCTUnwrap(delegateSpy.socialUser?.service)
        guard case .apple = service else {
            return XCTFail("Expected Apple social service, got \(service) instead")
        }
    }

    // showSignupEpilogue with loginFields.meta.appleUser set will not pass SocialService.apple to the delegate
    func testShowingSignupEpilogueWithoutAppleUser() throws {
        WordPressAuthenticator.initializeForTesting()
        let delegateSpy = WordPressAuthenticatorDelegateSpy()
        WordPressAuthenticator.shared.delegate = delegateSpy

        // This might be unnecessary because delegateSpy should be deallocated once the test method finished.
        // Leaving it here, just in case.
        addTeardownBlock {
            WordPressAuthenticator.shared.delegate = nil
        }

        let sut = AppleAuthenticator(signupService: SocialUserCreatingStub())

        // Before acting on the SUT, we need to ensure the login fields are set as we expect
        let presenterViewController = UIViewController()
        // We need to create this because it's accessed by showFrom(viewController:)
        _ = UINavigationController(rootViewController: presenterViewController)
        sut.showFrom(viewController: presenterViewController)

        sut.showSignupEpilogue(for: AuthenticatorCredentials())

        // The delegate is called, but without social service.
        //
        // By the way, the type system and runtime allow this to happen, but does it actually
        // make sense? Not so sure. How can we callback from Sign In with Apple without the
        // matching social service?
        XCTAssertTrue(delegateSpy.presentSignupEpilogueCalled)
        XCTAssertNil(delegateSpy.socialUser)
    }
}

// This doesn't live in a dedicated file because we currently only need it for this test.
class SocialUserCreatingStub: SocialUserCreating {

    // is new account, user name, WPCom token
    private let googleResult: Result<(Bool, String, String), Error>
    // is new account, existing non-social account, existing MFA account, user name, WPCom token
    private let appleResult: Result<(Bool, Bool, Bool, String, String), Error>

    init(
        appleResult: Result<(Bool, Bool, Bool, String, String), Error> = .failure(TestError(id: 1)),
        googleResult: Result<(Bool, String, String), Error> = .failure(TestError(id: 2))
    ) {
        self.appleResult = appleResult
        self.googleResult = googleResult
    }

    func createWPComUserWithGoogle(token: String, success: @escaping (Bool, String, String) -> Void, failure: @escaping (Error) -> Void) {
        switch googleResult {
        case .success((let isNewAccount, let userName, let wpComToken)):
            success(isNewAccount, userName, wpComToken)
        case .failure(let error):
            failure(error)
        }
    }

    func createWPComUserWithApple(token: String, email: String, fullName: String?, success: @escaping (Bool, Bool, Bool, String, String) -> Void, failure: @escaping (Error) -> Void) {
        switch appleResult {
        case .success((let isNewAccount, let existingNonSocialAccount, let existing2FAAccount, let username, let wpComToken)):
            success(isNewAccount, existingNonSocialAccount, existing2FAAccount, username, wpComToken)
        case .failure(let error):
            failure(error)
        }
    }
}
