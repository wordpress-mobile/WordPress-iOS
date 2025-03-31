import Foundation
import WordPressKit

struct SiteAddressViewModel {
    private let isSiteDiscovery: Bool
    private let xmlrpcFacade: WordPressXMLRPCAPIFacade
    private unowned let authenticationDelegate: WordPressAuthenticatorDelegate
    private let blogService: WordPressComBlogService
    private var loginFields: LoginFields

    private let tracker = AuthenticatorAnalyticsTracker.shared

    init(isSiteDiscovery: Bool,
         xmlrpcFacade: WordPressXMLRPCAPIFacade,
         authenticationDelegate: WordPressAuthenticatorDelegate,
         blogService: WordPressComBlogService,
         loginFields: LoginFields
    ) {
        self.isSiteDiscovery = isSiteDiscovery
        self.xmlrpcFacade = xmlrpcFacade
        self.authenticationDelegate = authenticationDelegate
        self.blogService = blogService
        self.loginFields = loginFields
    }

    enum GuessXMLRPCURLResult: Equatable {
        case success
        case error(NSError, String?)
        case troubleshootSite
        case customUI(UIViewController)
    }

    func guessXMLRPCURL(
        for siteAddress: String,
        loading: @escaping ((Bool) -> ()),
        completion: @escaping (GuessXMLRPCURLResult) -> ()
    ) {
        xmlrpcFacade.guessXMLRPCURL(forSite: siteAddress, success: { url in
            // Success! We now know that we have a valid XML-RPC endpoint.
            // At this point, we do NOT know if this is a WP.com site or a self-hosted site.
            if let url {
                self.loginFields.meta.xmlrpcURL = url as NSURL
            }

            completion(.success)

        }, failure: { error in
            guard let error else {
                return
            }
            // Intentionally log the attempted address on failures.
            // It's not guaranteed to be included in the error object depending on the error.
            WPAuthenticatorLogInfo("Error attempting to connect to site address: \(self.loginFields.siteAddress)")
            WPAuthenticatorLogError(error.localizedDescription)

            self.tracker.track(failure: .loginFailedToGuessXMLRPC)

            loading(false)

            guard self.isSiteDiscovery == false else {
                completion(.troubleshootSite)
                return
            }

            let err = self.originalErrorOrError(error: error as NSError)
            self.handleGuessXMLRPCURLError(error: err, loading: loading, completion: completion)
        })
    }

    private func handleGuessXMLRPCURLError(
        error: NSError,
        loading: @escaping ((Bool) -> ()),
        completion: @escaping (GuessXMLRPCURLResult) -> ()
    ) {
        let completion: (NSError, String?) -> Void = { error, errorMessage in
            if self.authenticationDelegate.shouldHandleError(error) {
                self.authenticationDelegate.handleError(error) { customUI in
                    completion(.customUI(customUI))
                }
                if let message = errorMessage {
                    self.tracker.track(failure: message)
                }
                return
            }

            completion(.error(error, errorMessage))
        }

        /// Confirm the site is not a WordPress site before describing it as an invalid WP site
        if let xmlrpcValidatorError = error as? WordPressOrgXMLRPCValidatorError, xmlrpcValidatorError == .invalid {
            loading(true)
            isWPSite { isWP in
                loading(false)
                if isWP {
                    let error = WordPressOrgXMLRPCValidatorError.xmlrpc_missing
                    completion(error as NSError, error.localizedDescription)
                } else {
                    completion(error, Strings.notWPSiteErrorMessage)
                }
            }
        } else if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCannotFindHost) ||
                    (error.domain == NSURLErrorDomain && error.code == NSURLErrorNetworkConnectionLost) {
            completion(error, Strings.notWPSiteErrorMessage)
        } else {
            completion(error, (error as? WordPressOrgXMLRPCValidatorError)?.localizedDescription)
        }
    }

    private func originalErrorOrError(error: NSError) -> NSError {
        guard let err = error.userInfo[XMLRPCOriginalErrorKey] as? NSError else {
            return error
        }

        return err
    }
}

extension SiteAddressViewModel {
    private func isWPSite(_ completion: @escaping (Bool) -> ()) {
        let baseSiteUrl = WordPressAuthenticator.baseSiteURL(string: loginFields.siteAddress)
        blogService.fetchUnauthenticatedSiteInfoForAddress(
            for: baseSiteUrl,
            success: { siteInfo in
                completion(siteInfo.isWP)
            },
            failure: { _ in
                completion(false)
            })
    }
}

private extension SiteAddressViewModel {
    struct Strings {
        static let notWPSiteErrorMessage = NSLocalizedString("The site at this address is not a WordPress site. For us to connect to it, the site must use WordPress.", comment: "Error message shown when a URL does not point to an existing site.")
    }
}
