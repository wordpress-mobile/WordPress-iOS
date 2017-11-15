private struct QueryRef<QueryType> where QueryType: Query {
    let query: QueryType
    let token = DispatchToken()
    init(_ query: QueryType) {
        self.query = query
    }
}

open class QueryStore<State, QueryType>: ReducerStore<State> where QueryType: Query {
    fileprivate var activeQueries = [QueryRef<QueryType>]() {
        didSet {
            processQueries(state: state, queries: activeQueries.map({$0.query}))
        }
    }

    public func run(query: QueryType) -> DispatchToken {
        let queryRef = QueryRef(query)
        activeQueries.append(queryRef)
        return queryRef.token
    }

    public func stopQuery(token: DispatchToken) {
        guard let index = activeQueries.index(where: { $0.token == token }) else {
            assertionFailure("Stopping a query that's not active")
            return
        }
        activeQueries.remove(at: index)
    }

    open func processQueries(state: State, queries: [QueryType]) {
        // Subclasses should implement this
    }
}
