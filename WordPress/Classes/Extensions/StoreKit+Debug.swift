import StoreKit

extension SKProduct {
    public override var description: String {
        return "<SKProduct: \(productIdentifier), title: \(localizedTitle)>"
    }
}

extension SKPaymentTransactionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case Purchasing:
            return "Purchasing"
        case Purchased:
            return "Purchased"
        case Failed:
            return "Failed"
        case Restored:
            return "Restored"
        case Deferred:
            return "Deferred"
        }
    }
}

extension SKPaymentTransaction {
    public override var description: String {
        let idString = transactionIdentifier.map({ " #\($0)" }) ?? ""
        let dateString = transactionDate.map({ " \($0)"}) ?? ""
        let errorString = error.map({ ". Error: \($0)" }) ?? ""
        return "<SKPaymentTransaction:\(idString)\(dateString) (\(transactionState)) for \(payment.productIdentifier)\(errorString)>"
    }
}
