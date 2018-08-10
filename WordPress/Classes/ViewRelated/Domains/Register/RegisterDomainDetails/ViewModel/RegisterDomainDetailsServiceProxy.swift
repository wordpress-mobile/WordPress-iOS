import Foundation

/// A proxy for being able to use dependency injection for RegisterDomainDetailsViewModel
/// especially for unittest mocking purposes
protocol RegisterDomainDetailsServiceProxyProtocol {

    func validateDomainContactInformation(contactInformation: [String: String],
                                          domainNames: [String],
                                          success: @escaping (ValidateDomainContactInformationResponse) -> Void,
                                          failure: @escaping (Error) -> Void)

    func getDomainContactInformation(success: @escaping (DomainContactInformation) -> Void,
                                     failure: @escaping (Error) -> Void)

    func getSupportedCountries(success: @escaping ([Country]) -> Void,
                               failure: @escaping (Error) -> Void)

    func getStates(for countryCode: String,
                   success: @escaping ([State]) -> Void,
                   failure: @escaping (Error) -> Void)

}

class RegisterDomainDetailsServiceProxy: RegisterDomainDetailsServiceProxyProtocol {

    private lazy var restApi: WordPressComRestApi = {
        let accountService = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        return accountService.defaultWordPressComAccount()?.wordPressComRestApi ?? WordPressComRestApi(oAuthToken: "")
    }()

    private lazy var domainsServiceRemote = {
        return DomainsServiceRemote(wordPressComRestApi: restApi)
    }()

    private lazy var transactionsServiceRemote = {
        return TransactionsServiceRemote(wordPressComRestApi: restApi)
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

    func getSupportedCountries(success: @escaping ([Country]) -> Void,
                               failure: @escaping (Error) -> Void) {
        transactionsServiceRemote.getSupportedCountries(success: success,
                                                        failure: failure)
    }

    func getStates(for countryCode: String,
                   success: @escaping ([State]) -> Void,
                   failure: @escaping (Error) -> Void) {
        domainsServiceRemote.getStates(for: countryCode,
                                       success: success,
                                       failure: failure)
    }
}
