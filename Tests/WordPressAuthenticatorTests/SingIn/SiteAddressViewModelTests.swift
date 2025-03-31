import XCTest
import WordPressKit
@testable import WordPressAuthenticator

final class SiteAddressViewModelTests: XCTestCase {
    private var isSiteDiscovery: Bool!
    private var xmlrpcFacade: MockWordPressXMLRPCAPIFacade!
    private var authenticationDelegateSpy: WordPressAuthenticatorDelegateSpy!
    private var blogService: MockWordPressComBlogService!
    private var loginFields: LoginFields!
    private var viewModel: SiteAddressViewModel!

    override func setUp() {
        super.setUp()
        isSiteDiscovery = false
        xmlrpcFacade = MockWordPressXMLRPCAPIFacade()
        authenticationDelegateSpy = WordPressAuthenticatorDelegateSpy()
        blogService = MockWordPressComBlogService()
        loginFields = LoginFields()

        WordPressAuthenticator.initializeForTesting()

        viewModel = SiteAddressViewModel(isSiteDiscovery: isSiteDiscovery, xmlrpcFacade: xmlrpcFacade, authenticationDelegate: authenticationDelegateSpy, blogService: blogService, loginFields: loginFields)
    }

    func testGuessXMLRPCURLSuccess() {
        xmlrpcFacade.success = true
        var result: SiteAddressViewModel.GuessXMLRPCURLResult?
        viewModel.guessXMLRPCURL(for: "https://wordpress.com", loading: { _ in }) { res in
            result = res
        }

        XCTAssertEqual(result, .success)
    }

    func testGuessXMLRPCURLError() {
        xmlrpcFacade.error = NSError(domain: "SomeDomain", code: 1, userInfo: nil)
        var result: SiteAddressViewModel.GuessXMLRPCURLResult?
        viewModel.guessXMLRPCURL(for: "https://error.com", loading: { _ in }) { res in
            result = res
        }
        if case .error(let error, _) = result {
            XCTAssertEqual(error.code, 1)
        } else {
            XCTFail("Unexpected result: \(String(describing: result))")
        }
    }

    func testGuessXMLRPCURLErrorInvalidNotWP() {
        xmlrpcFacade.error = WordPressOrgXMLRPCValidatorError.invalid as NSError
        blogService.isWP = false
        var result: SiteAddressViewModel.GuessXMLRPCURLResult?
        viewModel.guessXMLRPCURL(for: "https://invalid.com", loading: { _ in }) { res in
            result = res
        }

        if case .error(let error, _) = result {
            XCTAssertEqual(error.code, WordPressOrgXMLRPCValidatorError.invalid.rawValue)
        } else {
            XCTFail("Unexpected result: \(String(describing: result))")
        }
    }

    func testGuessXMLRPCURLErrorInvalidIsWP() {
        xmlrpcFacade.error = WordPressOrgXMLRPCValidatorError.invalid as NSError
        blogService.isWP = true
        var result: SiteAddressViewModel.GuessXMLRPCURLResult?
        viewModel.guessXMLRPCURL(for: "https://invalidwp.com", loading: { _ in }) { res in
            result = res
        }
        if case .error(let error, _) = result {
            XCTAssertEqual(error.code, WordPressOrgXMLRPCValidatorError.xmlrpc_missing.rawValue)
        } else {
            XCTFail("Unexpected result: \(String(describing: result))")
        }
    }

    func testGuessXMLRPCTroubleshootSite() {
        viewModel = SiteAddressViewModel(isSiteDiscovery: true, xmlrpcFacade: xmlrpcFacade, authenticationDelegate: authenticationDelegateSpy, blogService: blogService, loginFields: loginFields)
        xmlrpcFacade.error = NSError(domain: "SomeDomain", code: 1, userInfo: nil)
        var result: SiteAddressViewModel.GuessXMLRPCURLResult?
        viewModel.guessXMLRPCURL(for: "https://troubleshoot.com", loading: { _ in }) { res in
            result = res
        }
        XCTAssertEqual(result, .troubleshootSite)
    }

    func testGuessXMLRPCURLErrorHandledByDelegate() {
        xmlrpcFacade.error = NSError(domain: "SomeDomain", code: 1, userInfo: nil)
        authenticationDelegateSpy.shouldHandleError = true

        var result: SiteAddressViewModel.GuessXMLRPCURLResult?
        viewModel.guessXMLRPCURL(for: "https://delegatehandles.com", loading: { _ in }) { res in
            result = res
        }

        if case .customUI = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Unexpected result: \(String(describing: result))")
        }
    }
}

private class MockWordPressXMLRPCAPIFacade: WordPressXMLRPCAPIFacade {
    var success: Bool = false
    var error: NSError?

    override func guessXMLRPCURL(forSite siteAddress: String, success: @escaping (URL?) -> (), failure: @escaping (Error?) -> ()) {
        if self.success {
            success(URL(string: "https://successful.site"))
        } else {
            failure(self.error)
        }
    }
}

private class MockWordPressComBlogService: WordPressComBlogService {
    var isWP = false

    override func fetchUnauthenticatedSiteInfoForAddress(for address: String, success: @escaping (WordPressComSiteInfo) -> Void, failure: @escaping (Error) -> Void) {
        let siteInfo = WordPressComSiteInfo(remote: ["isWordPress": isWP])
        success(siteInfo)
    }
}
