private struct QueryRef<Query> {
    let query: Query
    let token = DispatchToken()
    init(_ query: Query) {
        self.query = query
    }
}

/// QueryStore provides a mechanism for Stores to keep track of queries by
/// consumers and perform operations depending of those.
///
/// A query in this context is a custom type that represents that a consumer is
/// interested in a certain subset of the data that the store provides, and
/// wants to get updates. The store can look at the activeQueries list and
/// decide if it needs to fetch data from the network to satisfy those queries.
///
/// Subclasses need to implement queriesChanged() and look at activeQueries and
/// their internal state to decide if they need to act.
///
open class QueryStore<State, Query>: StatefulStore<State>, Unsubscribable {
    fileprivate var activeQueryReferences = [QueryRef<Query>]() {
        didSet {
            queriesChanged()
        }
    }

    /// A list of active queries.
    ///
    public var activeQueries: [Query] {
        return activeQueryReferences.map({ $0.query })
    }

    /// Registers a query with the store.
    ///
    /// The query will be active as long as the consumer keeps a reference to
    /// the Receipt.
    public func query(_ query: Query) -> Receipt {
        let queryRef = QueryRef(query)
        activeQueryReferences.append(queryRef)
        return Receipt(token: queryRef.token, owner: self)
    }

    /// Unregisters the query associated with the given Receipt.
    ///
    public func unsubscribe(receipt: Receipt) {
        guard let index = activeQueryReferences.index(where: { $0.token == receipt.token }) else {
            assertionFailure("Stopping a query that's not active")
            return
        }
        activeQueryReferences.remove(at: index)
    }

    /// This method is called when the activeQueries list changes.
    ///
    /// Subclasses should implement this method and perform any necessary
    /// operations here.
    ///
    open func queriesChanged() {
        // Subclasses should implement this
    }
}
