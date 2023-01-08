import Foundation

fileprivate extension DispatchQueue {
    static let remoteConfigStoreQueue = DispatchQueue(label: "remote-config-store-queue")
}

class RemoteConfigStore {

    // MARK: Private Variables

    /// Thread Safety Coordinator
    private let queue: DispatchQueue
    private let remote: RemoteConfigRemote
    private let persistenceStore: UserPersistentRepository

    // MARK: Initializer

    init(queue: DispatchQueue = .remoteConfigStoreQueue,
         remote: RemoteConfigRemote = RemoteConfigRemote(wordPressComRestApi: .defaultApi()),
         persistenceStore: UserPersistentRepository = UserDefaults.standard) {
        self.queue = queue
        self.remote = remote
        self.persistenceStore = persistenceStore
    }

    // MARK: Public Functions

    /// Looks up the value for a remote config parameter.
    /// - Parameters:
    ///     - key: The key associated with a remote config parameter
    public func value(for key: String) -> Any? {
        return cache[key]
    }

    /// Fetches remote config values from the server.
    /// - Parameter callback: An optional callback that can be used to update UI following the fetch. It is not called on the UI thread.
    public func update(then callback: FetchCallback? = nil) {
        remote.getRemoteConfig { [weak self] result in
            switch result {
                case .success(let response):
                    self?.cache = response
                    DDLogInfo("🚩 Successfully updated remote config values: \(response)")
                    callback?()
                case .failure(let error):
                    DDLogError("🚩 Unable to update remote config values: \(error.localizedDescription)")
            }
        }
    }
}

extension RemoteConfigStore {
    struct Constants {
        static let CachedResponseKey = "RemoteConfigStoreCache"
    }

    typealias FetchCallback = () -> Void

    /// The local cache stores remote config values between runs so that the most recently fetched set are ready to go as soon as this object is instantiated.
    private var cache: [String: Any] {
        get {
            // Read from the cache in a thread-safe way
            queue.sync {
                persistenceStore.dictionary(forKey: Constants.CachedResponseKey) ?? [:]
            }
        }
        set {
            // Write to the cache in a thread-safe way.
            self.queue.sync {
                persistenceStore.set(newValue, forKey: Constants.CachedResponseKey)
            }
        }
    }
}
