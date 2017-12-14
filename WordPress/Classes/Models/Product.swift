import Foundation
import StoreKit

@objc
protocol Product {
    var localizedDescription: String { get }

    var localizedTitle: String { get }

    var price: NSDecimalNumber { get }

    var priceLocale: Locale { get }

    var productIdentifier: String { get }
}

extension SKProduct: Product {}

class MockProduct: NSObject, Product {
    let localizedDescription: String
    let localizedTitle: String
    let price: NSDecimalNumber
    var priceLocale: Locale
    let productIdentifier: String

    @objc init(localizedDescription: String, localizedTitle: String, price: NSDecimalNumber, priceLocale: Locale, productIdentifier: String) {
        self.localizedDescription = localizedDescription
        self.localizedTitle = localizedTitle
        self.price = price
        self.priceLocale = priceLocale
        self.productIdentifier = productIdentifier
    }
}
