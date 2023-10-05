import Foundation

protocol ShoppingCartServiceProtocol {
    func makeSiteCreationShoppingCart(
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

    func makeSiteCreationShoppingCart(
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
