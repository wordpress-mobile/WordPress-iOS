/// An Unsubscribable class can take a receipt and remove an associated
/// subscription.
///
public protocol Unsubscribable: class {
    func unsubscribe(receipt: Receipt)
}

/// A receipt is an object that's provided as a result from a subscription.
///
/// Said subscription will stay active as long as you keep a copy of the receipt.
/// When the receipt is released from memory, it will cancel the subscription.
///
/// This class is a wrapper around DispatchToken so you don't have to take care of
/// manually unsubscribing tokens.
///
public final class Receipt {
    /// The dispatch token associated with the receipt
    public let token: DispatchToken
    private weak var owner: Unsubscribable?

    init(token: DispatchToken, owner: Unsubscribable) {
        self.token = token
        self.owner = owner
    }

    deinit {
        owner?.unsubscribe(receipt: self)
    }
}
