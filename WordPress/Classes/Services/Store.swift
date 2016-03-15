import Foundation
import StoreKit

enum ProductRequestError: ErrorType {
    /// One of the requested product identifiers wasn't included in the response.
    case MissingProduct

    /// A product price couldn't be formatted into a String using the returned locale.
    case InvalidProductPrice
}

class LoggingTransactionObserver: NSObject, SKPaymentTransactionObserver {
    static let instance = LoggingTransactionObserver()
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        DDLogSwift.logInfo("Updated transactions: \(transactions)")
        for transaction in transactions {
            switch transaction.transactionState {
            case .Purchased, .Failed:
                queue.finishTransaction(transaction)
            default: break
            }
        }
    }
}

class StoreTransactionObserver: NSObject, SKPaymentTransactionObserver {
    static let instance = StoreTransactionObserver()
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            StoreCoordinator.instance.processTransaction(transaction)
        }
    }
}

class StoreCoordinator {
    static let instance = StoreCoordinator()
    var pendingPayment: (Plan, Int)? = nil

    func purchasePlan(plan: Plan, product: SKProduct, forSite siteID: Int) {
        precondition(plan.productIdentifier == product.productIdentifier)
        // TODO: fail better if there's a pending payment
        precondition(pendingPayment == nil)
        pendingPayment = (plan, siteID)
        // TODO: support mock store for testing
        let store = StoreKitStore()
        store.requestPayment(product)
    }

    func processTransaction(transaction: SKPaymentTransaction) {
        DDLogSwift.logInfo("[Store] Processing transaction \(transaction)")
        guard transaction.transactionState == .Purchased else {
            // Ignore other states for now
            if transaction.transactionState == .Failed {
                DDLogSwift.logInfo("[Store] Finishing failed transaction \(transaction)")
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
            } else {
                DDLogSwift.logInfo("[Store] Ignoring transaction \(transaction)")
            }
            return
        }
        assert(transaction.payment.productIdentifier == pendingPayment?.0.productIdentifier)
        guard let siteID = pendingPayment?.1,
            let plan = pendingPayment?.0,
            let service = PlanService(siteID: siteID, store: StoreKitStore()),
            let receiptURL = NSBundle.mainBundle().appStoreReceiptURL,
            let receipt = NSData(contentsOfURL: receiptURL)
            else {
                assertionFailure()
                return
        }
        DDLogSwift.logInfo("[Store] Verifying purchase for transaction \(transaction)")
        service.verifyPurchase(siteID, plan: plan, receipt: receipt, completion: { _ in
            DDLogSwift.logInfo("[Store] Finishing transaction \(transaction)")
            SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        })
    }
}

protocol Store {
    typealias ProductType: Product
    func getProductsWithIdentifiers(identifiers: Set<String>, success: [ProductType] -> Void, failure: ErrorType -> Void)
    func requestPayment(product: ProductType)
    var canMakePayments: Bool { get }
}

extension Store {
    /// Requests prices for the given plans.
    ///
    /// On success, it calls the `success` function with an array of prices. If
    /// one of the plans didn't have a product identifier, it's treated as a
    /// "free" plan and the returned price will be an empty string.
    func getPricesForPlans(plans: [Plan], success: [PricedPlan] -> Void, failure: ErrorType -> Void) {
        let identifiers = Set(plans.flatMap({ $0.productIdentifier }))
        getProductsWithIdentifiers(
            identifiers,
            success: { products in
                do {
                    let pricedPlans = try plans.map({ plan -> PricedPlan in
                        let price = try priceForPlan(plan, products: products)
                        return (plan, price)
                    })
                    success(pricedPlans)
                } catch let error {
                    failure(error)
                }
            },
            failure: failure
        )
    }
}

class StoreKitStore: Store {
    typealias ProductType = SKProduct
    func getProductsWithIdentifiers(identifiers: Set<String>, success: [ProductType] -> Void, failure: ErrorType -> Void) {
        let request = SKProductsRequest(productIdentifiers: identifiers)
        let delegate = ProductRequestDelegate(onSuccess: success, onError: failure)
        delegate.retainUntilFinished(request)
        delegate.retainUntilFinished(delegate)

        request.delegate = delegate

        request.start()
    }

    // FIXME @koke 2016-03-15
    // If we call this directly, the coordinator won't know what to do with this
    // since there will be no pending payment. Re-design the store architecture so
    // that's not possible.
    func requestPayment(product: ProductType) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }

    var canMakePayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
}

/// Mock Store to use while developing.
///
/// If you want to simulate a successful products request, use `MockStore.succeeding(after:)`.
///
/// If you want to simulate a failure, use `MockStore.failing(after:)`.
///
/// Both constructors support an optional `delay` parameter that defaults to 1 second.
struct MockStore: Store {
    typealias ProductType = MockProduct
    /// Response delay in seconds
    let delay: Double
    let succeeds: Bool

    init(delay: Double, succeeds: Bool) {
        self.delay = delay
        self.succeeds = succeeds
    }

    static func succeeding(after delay: Double = 1.0) -> MockStore {
        return MockStore(delay: delay, succeeds: true)
    }

    static func failing(after delay: Double = 1.0) -> MockStore {
        return MockStore(delay: delay, succeeds: false)
    }

    var products = [
        MockProduct(
            localizedDescription: "1 year of WordPress.com Premium",
            localizedTitle: "WordPress.com Premium 1 year",
            price: NSDecimalNumber(float: 99.88),
            priceLocale: NSLocale(localeIdentifier: "en-US"),
            productIdentifier: "com.wordpress.test.premium.subscription.1year"
        ),
        MockProduct(
            localizedDescription: "1 year of WordPress.com Business",
            localizedTitle: "WordPress.com Business 1 year",
            price: NSDecimalNumber(float: 299.88),
            priceLocale: NSLocale(localeIdentifier: "en-US"),
            productIdentifier: "com.wordpress.test.business.subscription.1year"
        )
    ]

    func getProductsWithIdentifiers(identifiers: Set<String>, success: [ProductType] -> Void, failure: ErrorType -> Void) {
        let products = identifiers.map({ identifier in
            return self.products.filter({ $0.productIdentifier == identifier }).first
        })
        if !products.filter({ $0 == nil }).isEmpty {
            failure(ProductRequestError.MissingProduct)
        } else {
            let products = products.flatMap({ $0 })

            let completion = {
                if (self.succeeds) {
                    success(products)
                } else {
                    failure(ProductRequestError.MissingProduct)
                }
            }
            if delay > 0 {
                dispatch_after(
                    dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))),
                    dispatch_get_main_queue(),
                    completion
                )
            } else {
                completion()
            }
        }
    }

    func requestPayment(product: ProductType) {
        // TODO
    }

    var canMakePayments = true
}

private class ProductRequestDelegate: NSObject, SKProductsRequestDelegate {
    typealias Success = [SKProduct] -> Void
    typealias Failure = ErrorType -> Void
    
    let onSuccess: Success
    let onError: Failure
    var retainedObjects = [NSObject]()

    init(onSuccess: Success, onError: Failure) {
        self.onSuccess = onSuccess
        self.onError = onError
        super.init()
    }

    func retainUntilFinished(object: NSObject) {
        retainedObjects.append(object)
    }
    
    @objc func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        if !response.invalidProductIdentifiers.isEmpty {
            DDLogSwift.logWarn("Invalid product identifiers: \(response.invalidProductIdentifiers)")
        }
        onSuccess(response.products)
    }
    
    @objc func request(request: SKRequest, didFailWithError error: NSError) {
        onError(error)
    }

    @objc func requestDidFinish(request: SKRequest) {
        retainedObjects.removeAll()
    }
}

private func priceForProduct(identifier: String, products: [Product]) throws -> String {
    guard let product = products.filter({ $0.productIdentifier == identifier }).first else {
        throw ProductRequestError.MissingProduct
    }
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.locale = product.priceLocale
    guard let price = formatter.stringFromNumber(product.price) else {
        throw ProductRequestError.InvalidProductPrice
    }
    return price
}

private func priceForPlan(plan: Plan, products: [Product]) throws -> String {
    guard let identifier = plan.productIdentifier else {
        return ""
    }
    return try priceForProduct(identifier, products: products)
}
