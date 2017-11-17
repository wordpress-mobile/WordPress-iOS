private struct QueryRef<QueryType> where QueryType: Query {
    let query: QueryType
    let token = DispatchToken()
    init(_ query: QueryType) {
        self.query = query
    }
}

public protocol QueryProcessor: class {
    func stop(query: QuerySubscription)
}

public class QuerySubscription {
    fileprivate let dispatchToken: DispatchToken
    private weak var processor: QueryProcessor?

    fileprivate init(dispatchToken: DispatchToken, processor: QueryProcessor) {
        self.dispatchToken = dispatchToken
        self.processor = processor
    }

    deinit {
        stopListening()
    }

    private func stopListening() {
        processor?.stop(query: self)
    }
}

open class QueryStore<State, QueryType>: StatefulStore<State>, QueryProcessor where QueryType: Query {
    fileprivate var activeQueryReferences = [QueryRef<QueryType>]() {
        didSet {
            queriesChanged()
        }
    }

    public var activeQueries: [QueryType] {
        return activeQueryReferences.map({ $0.query })
    }

    public func query(_ query: QueryType) -> QuerySubscription {
        let queryRef = QueryRef(query)
        activeQueryReferences.append(queryRef)
        return QuerySubscription(dispatchToken: queryRef.token, processor: self)
    }

    public func stop(query subscription: QuerySubscription) {
        stopQuery(token: subscription.dispatchToken)
    }

    fileprivate func stopQuery(token: DispatchToken) {
        guard let index = activeQueryReferences.index(where: { $0.token == token }) else {
            assertionFailure("Stopping a query that's not active")
            return
        }
        activeQueryReferences.remove(at: index)
    }

    open func queriesChanged() {
        // Subclasses should implement this
    }
}
