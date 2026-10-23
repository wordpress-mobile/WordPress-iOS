import Foundation
import WordPressData
import WordPressKit
import WordPressShared

fileprivate extension DispatchQueue {
    static let remoteConfigStoreQueue = DispatchQueue(label: "remote-config-store-queue")
}

class RemoteConfigStore {

    // MARK: Private Variables

    /// Thread Safety Coordinator
    private let queue: DispatchQueue
    private let remote: RemoteConfigRemote
    private let persistenceStore: UserPersistentRepository

    /// Minimum time between remote fetches. Calls to `update` within this
    /// interval serve the cache instead of hitting the network, unless forced.
    private let minimumRefreshInterval: TimeInterval

    // MARK: Initializer

    init(queue: DispatchQueue = .remoteConfigStoreQueue,
         remote: RemoteConfigRemote = RemoteConfigRemote(wordPressComRestApi: WordPressComRestApi.defaultApi()),
         persistenceStore: UserPersistentRepository = UserDefaults.standard,
         minimumRefreshInterval: TimeInterval = Constants.defaultMinimumRefreshInterval) {
        self.queue = queue
        self.remote = remote
        self.persistenceStore = persistenceStore
        self.minimumRefreshInterval = minimumRefreshInterval
    }

    // MARK: Public Functions

    /// Looks up the value for a remote config parameter.
    /// - Parameters:
    ///     - key: The key associated with a remote config parameter
    public func value(for key: String) -> Any? {
        return cache[key]
    }

    /// Fetches remote config values from the server.
    /// - Parameter force: When `true`, bypasses the minimum refresh interval.
    /// - Parameter callback: An optional callback that can be used to update UI following the fetch. It is not called on the UI thread.
    public func update(force: Bool = false, then callback: FetchCallback? = nil) {
        guard force || shouldFetch else {
            DDLogInfo("🚩 Skipping remote config update – fetched recently, serving cached values")
            callback?()
            return
        }

        remote.getRemoteConfig { [weak self] result in
            switch result {
                case .success(let response):
                    self?.cache = response
                    self?.lastFetchedDate = Date()
                    DDLogInfo("🚩 Successfully updated remote config values: \(response)")
                    callback?()
                case .failure(let error):
                    DDLogError("🚩 Unable to update remote config values: \(error.localizedDescription)")
            }
        }
    }

    /// Whether a remote fetch should happen now, given the last fetch time.
    private var shouldFetch: Bool {
        queue.sync {
            guard let lastFetchedDate = persistenceStore.object(forKey: Constants.LastFetchedDateKey) as? Date else {
                return true
            }
            return Date().timeIntervalSince(lastFetchedDate) >= minimumRefreshInterval
        }
    }
}

extension RemoteConfigStore {
    struct Constants {
        static let CachedResponseKey = "RemoteConfigStoreCache"
        static let LastFetchedDateKey = "RemoteConfigStoreLastFetchedDate"
        static let defaultMinimumRefreshInterval: TimeInterval = 5 * 60
    }

    typealias FetchCallback = () -> Void

    /// The last time the config values were successfully fetched from the server.
    private var lastFetchedDate: Date? {
        get {
            queue.sync {
                persistenceStore.object(forKey: Constants.LastFetchedDateKey) as? Date
            }
        }
        set {
            queue.sync {
                persistenceStore.set(newValue, forKey: Constants.LastFetchedDateKey)
            }
        }
    }

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
