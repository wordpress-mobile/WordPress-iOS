private struct QueryRef<QueryType> where QueryType: Query {
    let query: QueryType
    let token = DispatchToken()
    init(_ query: QueryType) {
        self.query = query
    }
}

open class QueryStore<State, QueryType>: StatefulStore<State>, Unsubscribable where QueryType: Query {
    fileprivate var activeQueryReferences = [QueryRef<QueryType>]() {
        didSet {
            queriesChanged()
        }
    }

    public var activeQueries: [QueryType] {
        return activeQueryReferences.map({ $0.query })
    }

    public func query(_ query: QueryType) -> Receipt {
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
