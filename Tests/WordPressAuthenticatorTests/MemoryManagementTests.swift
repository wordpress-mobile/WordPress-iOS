@testable import WordPressAuthenticator
import XCTest

final class MemoryManagementTests: XCTestCase {
    override func setUp() {
        super.setUp()

        WordPressAuthenticator.initialize(
          configuration: WordpressAuthenticatorProvider.wordPressAuthenticatorConfiguration(),
          style: WordpressAuthenticatorProvider.wordPressAuthenticatorStyle(.random),
          unifiedStyle: WordpressAuthenticatorProvider.wordPressAuthenticatorUnifiedStyle(.random)
        )
    }

    func testViewControllersDeallocatedAfterDismissing() {
        let viewControllers: [UIViewController] = [
            Storyboard.login.instance.instantiateInitialViewController()!,
            LoginPrologueLoginMethodViewController.instantiate(from: .login)!,
            LoginPrologueSignupMethodViewController.instantiate(from: .login)!,
            Login2FAViewController.instantiate(from: .login)!,
            LoginEmailViewController.instantiate(from: .login)!,
            LoginSelfHostedViewController.instantiate(from: .login)!,
            LoginSiteAddressViewController.instantiate(from: .login)!,
            LoginUsernamePasswordViewController.instantiate(from: .login)!,
            LoginWPComViewController.instantiate(from: .login)!,
            SignupEmailViewController.instantiate(from: .signup)!,
            SignupGoogleViewController.instantiate(from: .signup)!,
            GetStartedViewController.instantiate(from: .getStarted)!,
            VerifyEmailViewController.instantiate(from: .verifyEmail)!,
            PasswordViewController.instantiate(from: .password)!,
            TwoFAViewController.instantiate(from: .twoFA)!,
            GoogleAuthViewController.instantiate(from: .googleAuth)!,
            SiteAddressViewController.instantiate(from: .siteAddress)!,
            SiteCredentialsViewController.instantiate(from: .siteAddress)!
        ]

        for viewController in viewControllers {
            viewController.loadViewIfNeeded()
        }

        verifyObjectsDeallocatedAfterTeardown(viewControllers)
    }

    // MARK: - Helpers

    private func verifyObjectsDeallocatedAfterTeardown(_ objects: [AnyObject]) {
        /// Create the array of weak objects so we could assert them in the teardown block
        let weakObjects: [() -> AnyObject?] = objects.map { object in { [weak object] in
                return object
            }
        }

        /// All the weak items should be deallocated in the teardown block unless there's a retain cycle holding them
        addTeardownBlock {
            for object in weakObjects {
                XCTAssertNil(object(), "\(object()!.self) is not deallocated after teardown")
            }
        }
    }
}
