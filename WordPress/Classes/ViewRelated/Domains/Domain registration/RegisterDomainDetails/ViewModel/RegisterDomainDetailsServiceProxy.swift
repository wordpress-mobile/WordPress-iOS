import Foundation
import CoreData

/// Protocol for cart response, empty because there are no external details.
protocol CartResponseProtocol {}

extension CartResponse: CartResponseProtocol {}

/// A proxy for being able to use dependency injection for RegisterDomainDetailsViewModel
/// especially for unittest mocking purposes
protocol RegisterDomainDetailsServiceProxyProtocol {

    func validateDomainContactInformation(contactInformation: [String: String],
                                          domainNames: [String],
                                          success: @escaping (ValidateDomainContactInformationResponse) -> Void,
                                          failure: @escaping (Error) -> Void)

    func getDomainContactInformation(success: @escaping (DomainContactInformation) -> Void,
                                     failure: @escaping (Error) -> Void)

    func getSupportedCountries(success: @escaping ([WPCountry]) -> Void,
                               failure: @escaping (Error) -> Void)

    func getStates(for countryCode: String,
                   success: @escaping ([WPState]) -> Void,
                   failure: @escaping (Error) -> Void)

    func purchaseDomainUsingCredits(
        siteID: Int,
        domainSuggestion: DomainSuggestion,
        domainContactInformation: [String: String],
        privacyProtectionEnabled: Bool,
        success: @escaping (String) -> Void,
        failure: @escaping (Error) -> Void)

     func createTemporaryDomainShoppingCart(
        siteID: Int,
        domainSuggestion: DomainSuggestion,
        privacyProtectionEnabled: Bool,
        success: @escaping (CartResponseProtocol) -> Void,
        failure: @escaping (Error) -> Void)

    func createPersistentDomainShoppingCart(siteID: Int,
                                            domainSuggestion: DomainSuggestion,
                                            privacyProtectionEnabled: Bool,
                                            success: @escaping (CartResponseProtocol) -> Void,
                                            failure: @escaping (Error) -> Void)

    func redeemCartUsingCredits(cart: CartResponseProtocol,
                                domainContactInformation: [String: String],
                                success: @escaping () -> Void,
                                failure: @escaping (Error) -> Void)

    func setPrimaryDomain(
        siteID: Int,
        domain: String,
        success: @escaping () -> Void,
        failure: @escaping (Error) -> Void)
}

class RegisterDomainDetailsServiceProxy: RegisterDomainDetailsServiceProxyProtocol {

    private lazy var context = {
        ContextManager.sharedInstance().mainContext
    }()

    private lazy var restApi: WordPressComRestApi = {
        let accountService = AccountService(managedObjectContext: context)
        return accountService.defaultWordPressComAccount()?.wordPressComRestApi ?? WordPressComRestApi.defaultApi(oAuthToken: "")
    }()

    private lazy var domainService = {
        DomainsService(managedObjectContext: context, remote: domainsServiceRemote)
    }()

    private lazy var domainsServiceRemote = {
        DomainsServiceRemote(wordPressComRestApi: restApi)
    }()

    private lazy var transactionsServiceRemote = {
        TransactionsServiceRemote(wordPressComRestApi: restApi)
    }()

    func validateDomainContactInformation(contactInformation: [String: String],
                                          domainNames: [String],
                                          success: @escaping (ValidateDomainContactInformationResponse) -> Void,
                                          failure: @escaping (Error) -> Void) {
        domainsServiceRemote.validateDomainContactInformation(
            contactInformation: contactInformation,
            domainNames: domainNames,
            success: success,
            failure: failure
        )
    }

    func getDomainContactInformation(success: @escaping (DomainContactInformation) -> Void,
                                     failure: @escaping (Error) -> Void) {
        domainsServiceRemote.getDomainContactInformation(success: success,
                                                         failure: failure)
    }

    func getSupportedCountries(success: @escaping ([WPCountry]) -> Void,
                               failure: @escaping (Error) -> Void) {
        transactionsServiceRemote.getSupportedCountries(success: success,
                                                        failure: failure)
    }

    func getStates(for countryCode: String,
                   success: @escaping ([WPState]) -> Void,
                   failure: @escaping (Error) -> Void) {
        domainsServiceRemote.getStates(for: countryCode,
                                       success: success,
                                       failure: failure)
    }

    /// Convenience method to perform a full domain purchase.
    ///
    func purchaseDomainUsingCredits(
        siteID: Int,
        domainSuggestion: DomainSuggestion,
        domainContactInformation: [String: String],
        privacyProtectionEnabled: Bool,
        success: @escaping (String) -> Void,
        failure: @escaping (Error) -> Void) {

        let domainName = domainSuggestion.domainName

        createTemporaryDomainShoppingCart(
            siteID: siteID,
            domainSuggestion: domainSuggestion,
            privacyProtectionEnabled: privacyProtectionEnabled,
            success: { cart in
                self.redeemCartUsingCredits(
                    cart: cart,
                    domainContactInformation: domainContactInformation,
                    success: {
                        self.recordDomainPurchase(
                            siteID: siteID,
                            domain: domainName,
                            isPrimaryDomain: false)
                        success(domainName)
                    },
                    failure: failure)
            }, failure: failure)
    }

    /// Records that a domain purchase took place.
    ///
    func recordDomainPurchase(
        siteID: Int,
        domain: String,
        isPrimaryDomain: Bool) {

        let domain = Domain(
            domainName: domain,
            isPrimaryDomain: isPrimaryDomain,
            domainType: .registered)

        domainService.create(domain, forSite: siteID)

        if let blog = try? Blog.lookup(withID: siteID, in: context) {
            blog.hasDomainCredit = false
        }
    }

    func createTemporaryDomainShoppingCart(
        siteID: Int,
        domainSuggestion: DomainSuggestion,
        privacyProtectionEnabled: Bool,
        success: @escaping (CartResponseProtocol) -> Void,
        failure: @escaping (Error) -> Void) {

        transactionsServiceRemote.createTemporaryDomainShoppingCart(siteID: siteID,
                                                                    domainSuggestion: domainSuggestion,
                                                                    privacyProtectionEnabled: privacyProtectionEnabled,
                                                                    success: success,
                                                                    failure: failure)
    }

    func createPersistentDomainShoppingCart(siteID: Int,
                                            domainSuggestion: DomainSuggestion,
                                            privacyProtectionEnabled: Bool,
                                            success: @escaping (CartResponseProtocol) -> Void,
                                            failure: @escaping (Error) -> Void) {

        transactionsServiceRemote.createPersistentDomainShoppingCart(siteID: siteID,
                                                                     domainSuggestion: domainSuggestion,
                                                                     privacyProtectionEnabled: privacyProtectionEnabled,
                                                                     success: success,
                                                                     failure: failure)
    }

    func redeemCartUsingCredits(cart: CartResponseProtocol,
                                domainContactInformation: [String: String],
                                success: @escaping () -> Void,
                                failure: @escaping (Error) -> Void) {
        guard let cartResponse = cart as? CartResponse else {
            fatalError()
        }
        transactionsServiceRemote.redeemCartUsingCredits(cart: cartResponse,
                                                         domainContactInformation: domainContactInformation,
                                                         success: success,
                                                         failure: failure)
    }

    func setPrimaryDomain(siteID: Int,
                          domain: String,
                          success: @escaping () -> Void,
                          failure: @escaping (Error) -> Void) {

        if let blog = try? Blog.lookup(withID: siteID, in: context),
           let domains = blog.domains as? Set<ManagedDomain>,
           let newPrimaryDomain = domains.first(where: { $0.domainName == domain }) {

            for existingPrimaryDomain in domains.filter({ $0.isPrimary }) {
                existingPrimaryDomain.isPrimary = false
            }

            newPrimaryDomain.isPrimary = true

            ContextManager.shared.save(context)
        }

        domainsServiceRemote.setPrimaryDomainForSite(siteID: siteID,
                                                     domain: domain,
                                                     success: success,
                                                     failure: failure)
    }


}
