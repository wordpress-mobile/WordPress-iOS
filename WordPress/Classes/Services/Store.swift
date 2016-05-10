import Foundation
import StoreKit

enum ProductRequestError: ErrorType {
    /// One of the requested product identifiers wasn't included in the response.
    case MissingProduct

    /// A product price couldn't be formatted into a String using the returned locale.
    case InvalidProductPrice
}

class StoreKitTransactionObserver: NSObject, SKPaymentTransactionObserver {
    static let instance = StoreKitTransactionObserver()
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            StoreKitCoordinator.instance.processTransaction(transaction)
        }
    }
}

// This is a workaround for StoreCoordinator not being able to have a static
// stored property since it's a generic class.
struct StoreKitCoordinator {
    static let instance = StoreCoordinator(store: StoreKitStore())

    static let TransactionDidFinishNotification = "StoreCoordinatorTransactionDidFinishNotification"
    static let TransactionDidFailNotification   = "StoreCoordinatorTransactionDidFailNotification"
    static let NotificationProductIdentifierKey = "StoreCoordinatorNotificationProductIdentifierKey"
}

typealias PendingPayment = (productID: String, siteID: Int)

enum StoreCoordinatorError: ErrorType {
    case PaymentAlreadyInProgress
}

/// StoreCoordinator coordinates purchasing of products, processing of transactions, and
/// verification of purchases between the App Store (StoreKit) and WordPress.com.
///
/// Users of this class can simply attempt a purchase using `purchaseProduct(_:forSite)`,
/// and the coordinator will post a notification on a successful or failed purchase:
///
/// - `StoreKitCoordinator.TransactionDidFinishNotification` on success.
///   The notification's `userInfo` will contain the productID of the purchased
///   product under `StoreKitCoordinator.NotificationProductIdentifierKey`.
/// - `StoreKitCoordinator.TransactionDidFailNotification` on failure.
///   The notification's `userInfo` will also contain the productID of the attempted
///   purchased product, as well as a localized error message under `NSUnderlyingErrorKey`.
class StoreCoordinator<S: Store> {
    private let store: S
    private let database: KeyValueDatabase

    private var pendingPayment: PendingPayment? {
        set {
            if let pending = newValue {
                database.setObject(pending.productID, forKey: DatabaseKeys.pendingPaymentProductID)
                database.setObject(pending.siteID, forKey:DatabaseKeys.pendingPaymentSiteID)
            } else {
                database.removeObjectForKey(DatabaseKeys.pendingPaymentProductID)
                database.removeObjectForKey(DatabaseKeys.pendingPaymentSiteID)
            }
        }

        get {
            guard let productID = database.objectForKey(DatabaseKeys.pendingPaymentProductID) as? String,
                let siteID = database.objectForKey(DatabaseKeys.pendingPaymentSiteID) as? Int
                where siteID != 0 else { return nil }

            return (productID, siteID)
        }
    }

    init(store: S, database: KeyValueDatabase = NSUserDefaults()) {
        self.store = store
        self.database = database
    }

    /// Initiates a purchase for the specified product if a purchase isn't already in progress.
    ///
    /// - throws: A `StoreCoordinatorError.PaymentAlreadyInProgress` error if the purchase
    ///           fails immediately due to an already in progress purchase.
    ///
    func purchaseProduct(product: S.ProductType, forSite siteID: Int) throws {
        // We _should_ never have a pending payment at this point, so we'll fail in that case.
        guard pendingPayment == nil else {
            throw StoreCoordinatorError.PaymentAlreadyInProgress
        }

        pendingPayment = (product.productIdentifier, siteID)
        store.requestPayment(product)
    }

    private func processTransaction(transaction: SKPaymentTransaction) {
        DDLogSwift.logInfo("[Store] Processing transaction \(transaction)")
        switch transaction.transactionState {
        case .Purchasing: break
        case .Restored: break
        case .Failed:
            DDLogSwift.logInfo("[Store] Finishing failed transaction \(transaction)")
            finishTransaction(transaction)
        case .Deferred:
            DDLogSwift.logInfo("[Store] Transaction is deferred \(transaction)")
        case .Purchased:
            verifyTransaction(transaction)
        }
    }

    private func verifyTransaction(transaction: SKPaymentTransaction) {
        guard let pendingPayment = pendingPayment else {
            DDLogSwift.logInfo("[Store] Transaction with no pending payment information \(transaction)")

            // TODO: (@frosty 2016-04-27) Still attempt to verify purchase, sending only user info /
            // receipt data – we should at least be able to tell if this is a renewal.

            finishTransaction(transaction)
            return
        }

        assert(transaction.payment.productIdentifier == pendingPayment.productID)

        guard let service = PlanService(siteID: pendingPayment.siteID, store: StoreKitStore()),
            let receiptURL = NSBundle.mainBundle().appStoreReceiptURL,
            let receipt = NSData(contentsOfURL: receiptURL)
            else {
                assertionFailure()
                return
        }

        DDLogSwift.logInfo("[Store] Verifying purchase for transaction \(transaction)")
        service.verifyPurchase(pendingPayment.siteID, productID: pendingPayment.productID, receipt: receipt, completion: { [weak self] _ in
            // TODO: Handle success / failure of verification attempt
            self?.finishTransaction(transaction)
        })
    }

    private func finishTransaction(transaction: SKPaymentTransaction) {
        DDLogSwift.logInfo("[Store] Finishing transaction \(transaction)")

        SKPaymentQueue.defaultQueue().finishTransaction(transaction)

        guard let productID = pendingPayment?.productID else { return }

        if transaction.payment.productIdentifier == productID {
            pendingPayment = nil
        }

        var userInfo: [String: AnyObject] = [StoreKitCoordinator.NotificationProductIdentifierKey: productID]

        if let error = transaction.error {
            if error.code != SKErrorCode.PaymentCancelled.rawValue {
                userInfo[NSUnderlyingErrorKey] = error
            }

            postTransactionFailedNotification(userInfo)
        } else {
            postTransactionFinishedNotification(userInfo)
        }
    }

    private func postTransactionFailedNotification(userInfo: [NSObject: AnyObject]? = nil) {
        NSNotificationCenter.defaultCenter().postNotificationName(StoreKitCoordinator.TransactionDidFailNotification,
                                                                  object: nil,
                                                                  userInfo: userInfo)
    }

    private func postTransactionFinishedNotification(userInfo: [NSObject: AnyObject]? = nil) {
        NSNotificationCenter.defaultCenter().postNotificationName(StoreKitCoordinator.TransactionDidFinishNotification,
                                                                  object: nil,
                                                                  userInfo: userInfo)
    }

    /// Used to determine whether the specified plan is currently available for purchase
    /// for the specified site, given the current active plan.
    func purchaseAvailability(forPlan plan: Plan, siteID: Int, activePlan: Plan) -> PurchaseAvailability {
        guard store.canMakePayments
            && plan.isPaidPlan
            && plan != activePlan
            // Disallow upgrades/downgrades for now
            && activePlan.isFreePlan else {
            return .unavailable
        }
        if let pendingPayment = pendingPayment {
            if pendingPayment.productID == plan.productIdentifier && pendingPayment.siteID == siteID {
                return .pending
            } else {
                return .unavailable
            }
        } else {
            return .available
        }
    }
}

private struct DatabaseKeys {
    static let pendingPaymentProductID = "PendingPaymentProductIDDatabaseKey"
    static let pendingPaymentSiteID    = "PendingPaymentSiteIDDatabaseKey"
}

protocol Store {
    associatedtype ProductType: Product
    func getProductsWithIdentifiers(identifiers: Set<String>, success: [ProductType] -> Void, failure: ErrorType -> Void)
    func requestPayment(product: ProductType)
    var canMakePayments: Bool { get }
}

/// Represents if purchase is available for a specific plan and site
enum PurchaseAvailability {
    /// Purchases are not available for this site
    case unavailable
    /// There is an in-progress purchase for this site
    case pending
    /// The specified plan is available for purchase on this site
    case available
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
