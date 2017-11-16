private struct QueryRef<QueryType> where QueryType: Query {
    let query: QueryType
    let token = DispatchToken()
    init(_ query: QueryType) {
        self.query = query
    }
}

private protocol QueryProcessor: class {
    func stop(query: QuerySubscription)
}

public class QuerySubscription {
    private var dispatchToken: DispatchToken?
    private weak var processor: QueryProcessor?

    fileprivate init(dispatchToken: DispatchToken, processor: QueryProcessor) {
        self.dispatchToken = dispatchToken
        self.processor = processor
    }

    deinit {
        if dispatchToken != nil {
            stopListening()
        }
    }

    private func stopListening() {
        processor?.stop(query: self)
    }
}

open class QueryStore<State, QueryType>: StatefulStore<State> where QueryType: Query {
    fileprivate var activeQueries = [QueryRef<QueryType>]() {
        didSet {
            processQueries(state: state)
        }
    }

    public override var state: State {
        didSet {
            processQueries(state: state)
        }
    }

    public func run(query: QueryType) -> DispatchToken {
        let queryRef = QueryRef(query)
        activeQueries.append(queryRef)
        return queryRef.token
    }

    fileprivate func stopQuery(token: DispatchToken) {
        guard let index = activeQueries.index(where: { $0.token == token }) else {
            assertionFailure("Stopping a query that's not active")
            return
        }
        activeQueries.remove(at: index)
    }

    private func processQueries(state: State) {
        processQueries(state: state, queries: activeQueries.map({ $0.query }))
    }

    open func processQueries(state: State, queries: [QueryType]) {
        // Subclasses should implement this
    }
}
