import Foundation
import WordPressShared

@objc public class TransactionsServiceRemote: ServiceRemoteWordPressComREST {

    public enum ResponseError: Error {
        case decodingFailure
    }

    private enum Constants {
        static let freeDomainPaymentMethod = "WPCOM_Billing_WPCOM"
    }

    @objc public func getSupportedCountries(success: @escaping ([WPCountry]) -> Void,
                                            failure: @escaping (Error) -> Void) {
        let endPoint = "me/transactions/supported-countries/"
        let servicePath = path(forEndpoint: endPoint, withVersion: ._1_1)

        wordPressComRestApi.GET(servicePath,
                                parameters: nil,
                                success: {
                                    response, _ in
                                    do {
                                        guard let json = response as? [AnyObject] else {
                                            throw ResponseError.decodingFailure
                                        }
                                        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                                        let decodedResult = try JSONDecoder.apiDecoder.decode([WPCountry].self, from: data)
                                        success(decodedResult)
                                    } catch {
                                        DDLogError("Error parsing Supported Countries (\(error)): \(response)")
                                        failure(error)
                                    }
        }, failure: { error, _ in
            failure(error)
        })
    }

    /// Creates a shopping cart with products
    /// - Parameters:
    ///   - siteID: id of the current site
    ///   - products: an array of products to be added to the newly created cart
    ///   - temporary: true if the card is temporary, false otherwise
    public func createShoppingCart(siteID: Int?,
                                   products: [TransactionsServiceProduct],
                                   temporary: Bool,
                                   success: @escaping (CartResponse) -> Void,
                                   failure: @escaping (Error) -> Void) {
        let siteIDString = siteID != nil ? "\(siteID ?? 0)" : "no-site"
        let endPoint = "me/shopping-cart/\(siteIDString)"
        let urlPath = path(forEndpoint: endPoint, withVersion: ._1_1)

        var productsDictionary: [[String: AnyObject]] = []

        for product in products {
            switch product {
            case .domain(let domainSuggestion, let privacyProtectionEnabled):
                productsDictionary.append(["product_id": domainSuggestion.productID as AnyObject,
                                           "meta": domainSuggestion.domainName as AnyObject,
                                           "extra": ["privacy": privacyProtectionEnabled] as AnyObject])

            case .plan(let productId):
                productsDictionary.append(["product_id": productId as AnyObject])
            case .other(let productDict):
                productsDictionary.append(productDict)
            }
        }

        let parameters: [String: AnyObject] = ["temporary": (temporary ? "true" : "false") as AnyObject,
                                               "products": productsDictionary as AnyObject]

        wordPressComRestApi.POST(urlPath,
                                 parameters: parameters,
                                 success: { (response, _) in

            guard let jsonResponse = response as? [String: AnyObject],
                  let cart = CartResponse(jsonDictionary: jsonResponse),
                  !cart.products.isEmpty else {

                failure(TransactionsServiceRemote.ResponseError.decodingFailure)
                return
            }

            success(cart)
        }) { (error, _) in
            failure(error)
        }
    }

    // MARK: - Domains

    public func redeemCartUsingCredits(cart: CartResponse,
                                       domainContactInformation: [String: String],
                                       success: @escaping () -> Void,
                                       failure: @escaping (Error) -> Void) {

        let endPoint = "me/transactions"

        let urlPath = path(forEndpoint: endPoint, withVersion: ._1_1)

        let paymentDict = ["payment_method": Constants.freeDomainPaymentMethod]

        let parameters: [String: AnyObject] = ["domain_details": domainContactInformation as AnyObject,
                                               "cart": cart.jsonRepresentation() as AnyObject,
                                               "payment": paymentDict as AnyObject]

        wordPressComRestApi.POST(urlPath, parameters: parameters, success: { (_, _) in
            success()
        }) { (error, _) in
            failure(error)
        }
    }

    /// Creates a temporary shopping cart for a domain purchase
    @available(*, deprecated, message: "Use createShoppingCart(_:) and pass an array of specific products instead")
    public func createTemporaryDomainShoppingCart(siteID: Int,
                                                  domainSuggestion: DomainSuggestion,
                                                  privacyProtectionEnabled: Bool,
                                                  success: @escaping (CartResponse) -> Void,
                                                  failure: @escaping (Error) -> Void) {
        createShoppingCart(siteID: siteID,
                           products: [.domain(domainSuggestion, privacyProtectionEnabled)],
                           temporary: true,
                           success: success,
                           failure: failure)
    }

    /// Creates a persistent shopping  cart for a domain purchase
    @available(*, deprecated, message: "Use createShoppingCart(_:) and pass an array of specific products instead")
    public func createPersistentDomainShoppingCart(siteID: Int,
                                                   domainSuggestion: DomainSuggestion,
                                                   privacyProtectionEnabled: Bool,
                                                   success: @escaping (CartResponse) -> Void,
                                                   failure: @escaping (Error) -> Void) {
        createShoppingCart(siteID: siteID,
                           products: [.domain(domainSuggestion, privacyProtectionEnabled)],
                           temporary: false,
                           success: success,
                           failure: failure)
    }
}

public enum TransactionsServiceProduct {
    public typealias ProductId = Int
    public typealias PrivacyProtection = Bool

    case domain(DomainSuggestion, PrivacyProtection)
    case plan(ProductId)
    case other([String: AnyObject])
}

public struct CartResponse {

    public struct Product {
        let productID: Int
        let meta: String?
        let extra: [String: AnyObject]?

        fileprivate func jsonRepresentation() -> [String: AnyObject] {
            var returnDict: [String: AnyObject] = [:]

            returnDict["product_id"] = productID as AnyObject

            if let meta = meta {
                returnDict["meta"] = meta as AnyObject
            }

            if let extra = extra {
                returnDict["extra"] = extra as AnyObject
            }

            return returnDict
        }
    }

    let blogID: Int
    let cartKey: Any // cart key can be either Int or String
    let products: [Product]

    init?(jsonDictionary: [String: AnyObject]) {
        guard
            let cartKey = jsonDictionary["cart_key"],
            let blogID = jsonDictionary["blog_id"] as? Int,
            let products = jsonDictionary["products"] as? [[String: AnyObject]]
            else {
                return nil
        }

        let mappedProducts = products.compactMap { (product) -> Product? in
            guard
                let productID = product["product_id"] as? Int else {
                    return nil
            }
            let meta = product["meta"] as? String
            let extra = product["extra"] as? [String: AnyObject]

            return Product(productID: productID, meta: meta, extra: extra)
        }

        self.blogID = blogID
        self.cartKey = cartKey
        self.products = mappedProducts
    }

    fileprivate func jsonRepresentation() -> [String: AnyObject] {
        return ["blog_id": blogID as AnyObject,
                "cart_key": cartKey as AnyObject,
                "products": products.map { $0.jsonRepresentation() } as AnyObject]

    }
}
