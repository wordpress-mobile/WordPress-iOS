import XCTest
@testable import WordPressAuthenticator

// MARK: - WordPressAuthenticator Unit Tests
//
class WordPressAuthenticatorTests: XCTestCase {
    let timeout = TimeInterval(3)

    override class func setUp() {
        super.setUp()

        WordPressAuthenticator.initialize(
          configuration: WordpressAuthenticatorProvider.wordPressAuthenticatorConfiguration(),
          style: WordpressAuthenticatorProvider.wordPressAuthenticatorStyle(.random),
          unifiedStyle: WordpressAuthenticatorProvider.wordPressAuthenticatorUnifiedStyle(.random)
        )
    }

    func testBaseSiteURL() {
        var baseURL = "testsite.wordpress.com"
        var url = WordPressAuthenticator.baseSiteURL(string: "http://\(baseURL)")
        XCTAssert(url == "https://\(baseURL)", "Should force https for a wpcom site having http.")

        url = WordPressAuthenticator.baseSiteURL(string: baseURL)
        XCTAssert(url == "https://\(baseURL)", "Should force https for a wpcom site without a scheme.")

        baseURL = "www.selfhostedsite.com"
        url = WordPressAuthenticator.baseSiteURL(string: baseURL)
        XCTAssert((url == "https://\(baseURL)"), "Should add https:\\ for a non wpcom site missing a scheme.")

        url = WordPressAuthenticator.baseSiteURL(string: "\(baseURL)/wp-login.php")
        XCTAssert((url == "https://\(baseURL)"), "Should remove wp-login.php from the path.")

        url = WordPressAuthenticator.baseSiteURL(string: "\(baseURL)/wp-admin")
        XCTAssert((url == "https://\(baseURL)"), "Should remove /wp-admin from the path.")

        url = WordPressAuthenticator.baseSiteURL(string: "\(baseURL)/wp-admin/")
        XCTAssert((url == "https://\(baseURL)"), "Should remove /wp-admin/ from the path.")

        url = WordPressAuthenticator.baseSiteURL(string: "\(baseURL)/")
        XCTAssert((url == "https://\(baseURL)"), "Should remove a trailing slash from the url.")

        // Check non-latin characters and puny code
        baseURL = "http://例.例"
        let punycode = "http://xn--fsq.xn--fsq"
        url = WordPressAuthenticator.baseSiteURL(string: baseURL)
        XCTAssert(url == punycode)
        url = WordPressAuthenticator.baseSiteURL(string: punycode)
        XCTAssert(url == punycode)
    }

    func testBaseSiteURLKeepsHTTPSchemeForNonWPSites() {
        let url = "http://selfhostedsite.com"
        let correctedURL = WordPressAuthenticator.baseSiteURL(string: url)
        XCTAssertEqual(correctedURL, url)
    }

    // MARK: WordPressAuthenticator Notification Tests
    func testDispatchesSupportPushNotificationReceived() {
        let authenticator = WordpressAuthenticatorProvider.getWordpressAuthenticator()
        _ = expectation(forNotification: .wordpressSupportNotificationReceived, object: nil, handler: nil)

        authenticator.supportPushNotificationReceived()

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testDispatchesSupportPushNotificationCleared() {
        let authenticator = WordpressAuthenticatorProvider.getWordpressAuthenticator()
        _ = expectation(forNotification: .wordpressSupportNotificationCleared, object: nil, handler: nil)

        authenticator.supportPushNotificationCleared()

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: View Tests
    func testWordpressAuthIsAuthenticationViewController() {
        let loginViewcontroller = LoginViewController()
        let nuxViewController = NUXViewController()
        let nuxTableViewController = NUXTableViewController()
        let basicViewController = UIViewController()

        XCTAssertTrue(WordPressAuthenticator.isAuthenticationViewController(loginViewcontroller))
        XCTAssertTrue(WordPressAuthenticator.isAuthenticationViewController(nuxViewController))
        XCTAssertTrue(WordPressAuthenticator.isAuthenticationViewController(nuxTableViewController))
        XCTAssertFalse(WordPressAuthenticator.isAuthenticationViewController(basicViewController))
    }

    func testShowLoginFromPresenterReturnsLoginInitialVC() {
        let presenterSpy = ModalViewControllerPresentingSpy()
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { (_, _) -> Bool in
            return presenterSpy.presentedVC != nil
        }), object: .none)

        WordPressAuthenticator.showLoginFromPresenter(presenterSpy, animated: true)
        wait(for: [expectation], timeout: timeout)

        XCTAssertTrue(presenterSpy.presentedVC is LoginNavigationController)
    }

    func testShowLoginForJustWPComPresentsCorrectVC() {
        let presenterSpy = ModalViewControllerPresentingSpy()
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { (_, _) -> Bool in
            return presenterSpy.presentedVC != nil
        }), object: .none)

        WordPressAuthenticator.showLoginForJustWPCom(from: presenterSpy)
        wait(for: [expectation], timeout: timeout)

        XCTAssertTrue(presenterSpy.presentedVC is LoginNavigationController)
    }

    func testSignInForWPOrgReturnsVC() {
        let vc = WordPressAuthenticator.signinForWPOrg()

        XCTAssertTrue(vc is LoginSiteAddressViewController)
    }

    func testShowLoginForJustWPComSetsMetaProperties() throws {
        let presenterSpy = ModalViewControllerPresentingSpy()
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { (_, _) -> Bool in
            return presenterSpy.presentedVC != nil
        }), object: .none)

        WordPressAuthenticator.showLoginForJustWPCom(from: presenterSpy,
                                                     jetpackLogin: false,
                                                     connectedEmail: "email-address@example.com")

        let navController = try XCTUnwrap(presenterSpy.presentedVC as? LoginNavigationController)
        let controller = try XCTUnwrap(navController.viewControllers.first as? LoginEmailViewController)

        wait(for: [expectation], timeout: timeout)

        XCTAssertEqual(controller.loginFields.restrictToWPCom, true)
        XCTAssertEqual(controller.loginFields.username, "email-address@example.com")
    }

    func testShowLoginForSelfHostedSitePresentsCorrectVC() {
        let presenterSpy = ModalViewControllerPresentingSpy()
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { (_, _) -> Bool in
            return presenterSpy.presentedVC != nil
        }), object: .none)

        WordPressAuthenticator.showLoginForSelfHostedSite(presenterSpy)
        wait(for: [expectation], timeout: timeout)

        XCTAssertTrue(presenterSpy.presentedVC is LoginNavigationController)
    }

    func testSignInForWPComWithLoginFieldsReturnsVC() throws {
        let navController = try XCTUnwrap(WordPressAuthenticator.signinForWPCom(dotcomEmailAddress: "example@email.com", dotcomUsername: "username") as? UINavigationController)
        let vc = navController.topViewController

        XCTAssertTrue(vc is LoginWPComViewController)
    }

    func testSignInForWPComSetsEmptyLoginFields() throws {
        let navController = try XCTUnwrap(WordPressAuthenticator.signinForWPCom(dotcomEmailAddress: nil, dotcomUsername: nil) as? UINavigationController)
        let vc = try XCTUnwrap(navController.topViewController as? LoginWPComViewController)

        XCTAssertEqual(vc.loginFields.emailAddress, "")
        XCTAssertEqual(vc.loginFields.username, "")
    }

    // MARK: WordPressAuthenticator URL verification Tests
    func testIsGoogleAuthURL() {
        let authenticator = WordpressAuthenticatorProvider.getWordpressAuthenticator()
        let googleURL = URL(string: "com.googleuserconsent.apps/82ekn2932nub23h23hn3")!
        let magicLinkURL = URL(string: "https://magic-login")!
        let wordpressComURL = URL(string: "https://WordPress.com")!

        XCTAssertTrue(authenticator.isGoogleAuthUrl(googleURL))
        XCTAssertFalse(authenticator.isGoogleAuthUrl(magicLinkURL))
        XCTAssertFalse(authenticator.isGoogleAuthUrl(wordpressComURL))
    }

    func testIsWordPressAuthURL() {
        let authenticator = WordpressAuthenticatorProvider.getWordpressAuthenticator()
        let magicLinkURL = URL(string: "https://magic-login")!
        let googleURL = URL(string: "https://google.com")!
        let wordpressComURL = URL(string: "https://WordPress.com")!

        XCTAssertTrue(authenticator.isWordPressAuthUrl(magicLinkURL))
        XCTAssertFalse(authenticator.isWordPressAuthUrl(googleURL))
        XCTAssertFalse(authenticator.isWordPressAuthUrl(wordpressComURL))
    }

    func testHandleWordPressAuthURLReturnsTrueOnSuccess() {
        let authenticator = WordpressAuthenticatorProvider.getWordpressAuthenticator()
        let url = URL(string: "https://wordpress.com/wp-login.php?token=1234567890%26action&magic-login&sr=1&signature=1234567890oienhdtsra&flow=signup")

        XCTAssertTrue(authenticator.handleWordPressAuthUrl(url!, rootViewController: UIViewController(), automatedTesting: true))
    }
}
