public protocol CachableState: Codable {
    static func emptyState() -> Self
}

fileprivate extension CachableState {
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

/// CachedStore is a subclass of QueryStore that implements offline cache functionality.
/// It transparently handles persisting `State` to the disk when there are no longer any active `Queries`,
/// as well as removing current `State` from memory, as a performance optimisation.
///
/// You can also manually force writing of the cache file by calling `storeCachedState()`.
///
/// CachedStore requires your `State` to conform to the `CachableState` protocol.
///
/// Subclasses should call `super` when overriding `queriesChanged()`.
///
open class CachedStore<State: CachableState, Query>: QueryStore<State, Query> {

    var memoryState: State?

    public init() {
        let initialState = type(of: self).initialState()
        memoryState = initialState
        super.init(initialState: initialState)
    }

    public override var state: State {
        get {
            guard let currentState = memoryState else {
                // If we purged the in-memory `State` and the `Store` is being asked to do
                // work again, let's try to reinitialise it from cache.
                let cachedState = type(of: self).initialState()
                memoryState = cachedState
                return cachedState
            }

            return currentState
        }
        set {
            memoryState = newValue
            emitStateChange(old: state, new: newValue)
        }
    }

    open override func queriesChanged() {
        if activeQueries.isEmpty {
            storeCachedState()
            purgeMemoryState()
            return
        }
    }

    public final func storeCachedState() {
        do {
            let jsonEncoder = JSONEncoder.init()
            let encodedStore = try jsonEncoder.encode(state)

            try encodedStore.write(to: try type(of: self).cacheFileURL(), options: [.atomic])
        } catch {
            NSLog("[PluginStore Error] \(error)")
        }
    }

    private final func purgeMemoryState() {
        memoryState = nil
    }

    private static func initialState() -> State {
        guard let url = try? cacheFileURL(), let state = State.cachedState(from: url) else {
            return State.emptyState()
        }

        return state
    }

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
