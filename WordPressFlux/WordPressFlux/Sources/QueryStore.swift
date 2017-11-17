private struct QueryRef<Query> {
    let query: Query
    let token = DispatchToken()
    init(_ query: Query) {
        self.query = query
    }
}

open class QueryStore<State, Query>: StatefulStore<State>, Unsubscribable {
    fileprivate var activeQueryReferences = [QueryRef<Query>]() {
        didSet {
            queriesChanged()
        }
    }

    public var activeQueries: [Query] {
        return activeQueryReferences.map({ $0.query })
    }

    public func query(_ query: Query) -> Receipt {
        let queryRef = QueryRef(query)
        activeQueryReferences.append(queryRef)
        return Receipt(token: queryRef.token, owner: self)
    }

    public func unsubscribe(receipt: Receipt) {
        guard let index = activeQueryReferences.index(where: { $0.token == receipt.token }) else {
            assertionFailure("Stopping a query that's not active")
            return
        }
        activeQueryReferences.remove(at: index)
    }

    open func queriesChanged() {
        // Subclasses should implement this
    }
}
