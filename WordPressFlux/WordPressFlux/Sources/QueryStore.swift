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
    fileprivate var activeQueries = [QueryRef<QueryType>]() {
        didSet {
            processQueries()
        }
    }

    public override var state: State {
        didSet {
            processQueries()
        }
    }

    public func run(query: QueryType) -> QuerySubscription {
        let queryRef = QueryRef(query)
        activeQueries.append(queryRef)
        return QuerySubscription(dispatchToken: queryRef.token, processor: self)
    }

    public func stop(query subscription: QuerySubscription) {
        stopQuery(token: subscription.dispatchToken)
    }

    fileprivate func stopQuery(token: DispatchToken) {
        guard let index = activeQueries.index(where: { $0.token == token }) else {
            assertionFailure("Stopping a query that's not active")
            return
        }
        activeQueries.remove(at: index)
    }

    private func processQueries() {
        processQueries(queries: activeQueries.map({ $0.query }))
    }

    open func processQueries(queries: [QueryType]) {
        // Subclasses should implement this
    }
}
