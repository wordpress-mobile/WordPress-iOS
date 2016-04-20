import Foundation
import StoreKit

@objc
protocol Product {
    var localizedDescription: String { get }
    
    var localizedTitle: String { get }
    
    var price: NSDecimalNumber { get }
    
    var priceLocale: NSLocale { get }
    
    var productIdentifier: String { get }
}

extension SKProduct: Product {}

extension SKProduct {
    public override var description: String {
        return "<SKProduct: \(productIdentifier), title: \(localizedTitle)>"
    }
}

class MockProduct: NSObject, Product {
    let localizedDescription: String
    let localizedTitle: String
    let price: NSDecimalNumber
    var priceLocale: NSLocale
    let productIdentifier: String

    init(localizedDescription: String, localizedTitle: String, price: NSDecimalNumber, priceLocale: NSLocale, productIdentifier: String) {
        self.localizedDescription = localizedDescription
        self.localizedTitle = localizedTitle
        self.price = price
        self.priceLocale = priceLocale
        self.productIdentifier = productIdentifier
    }
}
