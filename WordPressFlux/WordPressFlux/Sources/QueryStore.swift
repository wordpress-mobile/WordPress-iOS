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
/// If your `State` type confrorms to the `CachableState` protocol, the `QueryStore`
/// will transparently persist/load cached State and purge in-memory State when there are no
/// longer any active `Queries` associated with the `Store`.
////
/// You can also manually force writing of the cache file by calling `storeCachedState()`.
///

open class QueryStore<State, Query>: StatefulStore<State>, Unsubscribable {
    private let initialState: State

    fileprivate var activeQueryReferences = [QueryRef<Query>]() {
        didSet {
            if activeQueryReferences.isEmpty, let encodableState = state as? Encodable, let url = try? type(of: self).cacheFileURL() {
                // If we don't have any active queries, and the `state` conforms to `Encodable`, let's use this as our cue to persist the data
                // to disk and get rid of the in-memory cache.
                inMemoryState = nil
                encodableState.storeCachedState(at: url)
            }

            queriesChanged()
        }
    }

    /// In-memory storage for `state`.
    private var inMemoryState: State?

    /// Facade for the `state`.
    ///
    /// It allows for the lazy-loading of `state` from cache, when `State` conforms to `Codable`.
    override public final var state: State {
        get {
            // If the in-memory State is populated, just return that.
            guard inMemoryState == nil else {
                return inMemoryState!
            }

            // If we purged the in-memory `State` and the `Store` is being asked to do
            // work again, let's try to reinitialise it from cache.
            guard let codableInitialState = initialState as? Codable,
                let cacheFileURL = try? type(of: self).cacheFileURL(),
                let cachedState = type(of: codableInitialState).cachedState(from: cacheFileURL) as? State else {
                    // If reading persisted state fails, let's just fail over to `initialState`.
                    return initialState
            }

            // When reading from disk has succeeded, set the result as `inMemoryState` and return it.
            inMemoryState = cachedState
            return cachedState
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


    override public init(initialState: State, dispatcher: ActionDispatcher) {
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

// In ideal world, those wouldn't be extensions on `Encodable`/`Codable`, but rather refinements of
// `QueryStore` in which `Store` conforms to `Codable` — then we would just change behavior _inside_ the `QueryStore`,
// based on whether the type conforms to `Codable` or not.
// Regretfully, Swift type system (or my Swift skills) does't allow to express that —
// you can't just do `let codableSelf = self as? QueryStore<Codable, Query>` because
// _Codable itself doesn't conform to Codable_.
private extension Encodable {
    func storeCachedState(at url: URL) {
        do {
            let jsonEncoder = JSONEncoder.init()
            let encodedStore = try jsonEncoder.encode(self)

            try encodedStore.write(to: url, options: [.atomic])
        } catch {
            NSLog("[PluginStore Error] \(error)")
        }
    }
}

private extension Decodable {
    static func cachedState(from cachedURL: URL) -> Self? {
        do {
            let data = try Data(contentsOf: cachedURL)
            let state = try JSONDecoder().decode(Self.self, from: data)

            return state
        } catch {
            NSLog("[PluginStore Error] \(error)")
            return nil
        }
    }
}

private extension QueryStore {
    private static func cacheFileURL() throws -> URL {
        let cacheFilename =  "\(String(describing: self)).json"
        let documentsPath = try FileManager.default.url(for: .cachesDirectory,
                                                        in: .userDomainMask,
                                                        appropriateFor: nil,
                                                        create: true)

        let targetURL = documentsPath.appendingPathComponent(cacheFilename)

        return targetURL
    }
}

extension QueryStore where State: Encodable {
    public func storeCachedState() {
        guard let url = try? type(of: self).cacheFileURL() else {
            return
        }

        state.storeCachedState(at: url)
    }
}
