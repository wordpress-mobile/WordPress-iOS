import Foundation

/// Provides information about available products for user purchases, such as plans, domains, etc.
///
open class ProductServiceRemote {
    public struct Product {
        public let id: Int
        public let key: String
        public let name: String
        public let slug: String
        public let description: String
        public let currencyCode: String?
        public let saleCost: Double?

        public func saleCostForDisplay() -> String? {
            guard let currencyCode = currencyCode,
                  let saleCost = saleCost else {
                      return nil
            }

            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            numberFormatter.currencyCode = currencyCode

            return numberFormatter.string(from: NSNumber(value: saleCost))
        }
    }

    let serviceRemote: ServiceRemoteWordPressComREST

    public enum GetProductError: Error {
        case failedCastingProductsToDictionary(Any)
    }

    public init(restAPI: WordPressComRestApi) {
        serviceRemote = ServiceRemoteWordPressComREST(wordPressComRestApi: restAPI)
    }

    /// Gets a list of available products for purchase.
    ///
    open func getProducts(completion: @escaping (Result<[Product], Error>) -> Void) {
        let path = serviceRemote.path(forEndpoint: "products", withVersion: ._1_1)

        serviceRemote.wordPressComRESTAPI.get(
            path,
            parameters: [:],
            success: { responseProducts, _ in
                guard let productsDictionary = responseProducts as? [String: [String: Any]] else {
                    completion(.failure(GetProductError.failedCastingProductsToDictionary(responseProducts)))
                    return
                }

                let products = productsDictionary.compactMap { (key: String, value: [String: Any]) -> Product? in
                    guard let productID = value["product_id"] as? Int else {
                        return nil
                    }

                    let name = (value["product_name"] as? String) ?? ""
                    let slug = (value["product_slug"] as? String) ?? ""
                    let description = (value["description"] as? String) ?? ""
                    let currencyCode = value["currency_code"] as? String
                    let saleCost = value["sale_cost"] as? Double

                    return Product(
                        id: productID,
                        key: key,
                        name: name,
                        slug: slug,
                        description: description,
                        currencyCode: currencyCode,
                        saleCost: saleCost)
                }

                completion(.success(products))
            },
            failure: { error, _ in
                completion(.failure(error))
            }
        )
    }
}
