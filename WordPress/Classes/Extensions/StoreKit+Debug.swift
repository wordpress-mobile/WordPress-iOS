import StoreKit

extension SKProduct {
    override open var description: String {
        return "<SKProduct: \(productIdentifier), title: \(localizedTitle)>"
    }
}

extension SKPaymentTransactionState: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .purchasing:
            return "Purchasing"
        case .purchased:
            return "Purchased"
        case .failed:
            return "Failed"
        case .restored:
            return "Restored"
        case .deferred:
            return "Deferred"
        @unknown default:
            fatalError()
        }
    }
}

extension SKPaymentTransaction {
    override open var description: String {
        let idString = transactionIdentifier.map({ " #\($0)" }) ?? ""
        let dateString = transactionDate.map({ " \($0)"}) ?? ""
        let errorString = error.map({ ". Error: \($0)" }) ?? ""
        return "<SKPaymentTransaction:\(idString)\(dateString) (\(transactionState)) for \(payment.productIdentifier)\(errorString)>"
    }
}
