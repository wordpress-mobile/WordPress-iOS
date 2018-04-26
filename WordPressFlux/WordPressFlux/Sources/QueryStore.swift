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
/// If your `State` type confrorms to the `Codable` protocol, the `QueryStore`
/// will transparently persist/load State and purge in-memory State when there are no
/// longer any active `Queries` associated with the `Store`.
////
/// You can also manually force writing out the state to disk by calling `persistState()`.
///

open class QueryStore<State, Query>: StatefulStore<State>, Unsubscribable {
    private let initialState: State

    fileprivate var activeQueryReferences = [QueryRef<Query>]() {
        didSet {
            if activeQueryReferences.isEmpty, let encodableState = state as? Encodable, let url = try? type(of: self).persistenceURL() {
                // If we don't have any active queries, and the `state` conforms to `Encodable`, let's use this as our cue to persist the data
                // to disk and get rid of the in-memory cache.
                do {
                try encodableState.saveJSON(at: url)
                    inMemoryState = nil
                } catch {
                    NSLog("[PluginStore Error] \(error)")
                }
            }

            queriesChanged()
        }
    }

    /// In-memory storage for `state`.
    private var inMemoryState: State?

    /// Facade for the `state`.
    ///
    /// It allows for the lazy-loading of `state` from disk, when `State` conforms to `Codable`.
    override public final var state: State {
        get {
            // If the in-memory State is populated, just return that.
            if let inMemoryState = inMemoryState {
                return inMemoryState
            }

            // If we purged the in-memory `State` and the `Store` is being asked to do
            // work again, let's try to reinitialise it from disk.
            guard let codableInitialState = initialState as? Codable,
                let persistenceURL = try? type(of: self).persistenceURL(),
                let persistedState = type(of: codableInitialState).loadJSON(from: persistenceURL) as? State else {
                    // If reading persisted state fails, let's just fail over to `initialState`.
                    return initialState
            }

            // When reading from disk has succeeded, set the result as `inMemoryState` and return it.
            inMemoryState = persistedState
            return persistedState
        }
        set {
            inMemoryState = newValue
            emitStateChange(old: state, new: newValue)
        }
    }

    /// A list of active queries.
    ///
    public var activeQueries: [Query] {
        return activeQueryReferences.map({ $0.query })
    }


    override public init(initialState: State, dispatcher: ActionDispatcher = .global) {
        self.initialState = initialState
        super.init(initialState: initialState, dispatcher: dispatcher)
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

public extension Encodable {
    func saveJSON(at url: URL, using encoder: JSONEncoder = JSONEncoder()) throws {
        let encodedStore = try encoder.encode(self)
        try encodedStore.write(to: url, options: [.atomic])
    }
}

public extension Decodable {
    static func loadJSON(from url: URL, using decoder: JSONDecoder = JSONDecoder()) -> Self? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        do {
            let state = try decoder.decode(Self.self, from: data)

            return state
        } catch {
            NSLog("[Decoding error] Error while decoding file at \(url): \(error)")
            return nil
        }
    }
}

private extension QueryStore {
    private static func persistenceURL() throws -> URL {
        let filename =  "\(String(describing: self)).json"
        let documentsPath = try FileManager.default.url(for: .cachesDirectory,
                                                        in: .userDomainMask,
                                                        appropriateFor: nil,
                                                        create: true)

        let targetURL = documentsPath.appendingPathComponent(filename)

        return targetURL
    }
}

extension QueryStore where State: Encodable {
    public func persistState() throws {
        guard let url = try? type(of: self).persistenceURL() else {
            return
        }

        try state.saveJSON(at: url)
    }
}
