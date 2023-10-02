import Foundation

/// A proxy for being able to use dependency injection for RegisterDomainDetailsViewModel
/// especially for unittest mocking purposes
protocol ShoppingCartServiceProtocol {
    func createSiteCreationShoppingCart(
        siteID: Int,
        domainSuggestion: DomainSuggestion,
        privacyProtectionEnabled: Bool,
        planId: Int,
        success: @escaping (CartResponseProtocol) -> Void,
        failure: @escaping (Error) -> Void)
}

final class ShoppingCartService: ShoppingCartServiceProtocol {
    private lazy var context = {
        ContextManager.sharedInstance().mainContext
    }()

    private lazy var restApi: WordPressComRestApi = {
        let account = try? WPAccount.lookupDefaultWordPressComAccount(in: context)
        return account?.wordPressComRestApi ?? WordPressComRestApi.defaultApi(oAuthToken: "")
    }()

    private lazy var transactionsServiceRemote = {
        TransactionsServiceRemote(wordPressComRestApi: restApi)
    }()

    func createSiteCreationShoppingCart(
        siteID: Int,
        domainSuggestion: DomainSuggestion,
        privacyProtectionEnabled: Bool,
        planId: Int,
        success: @escaping (CartResponseProtocol) -> Void,
        failure: @escaping (Error) -> Void) {
            var products: [TransactionsServiceProduct] = [.plan(planId)]

            if !domainSuggestion.isFree {
                products.append(.domain(domainSuggestion, privacyProtectionEnabled))
            }

            transactionsServiceRemote.createShoppingCart(siteID: siteID,
                                                         products: products,
                                                         temporary: false,
                                                         success: success,
                                                         failure: failure)
        }
}
