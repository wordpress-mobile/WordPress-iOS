import Foundation
import WordPressShared
import WordPressKit

class RemoteFeatureFlagStore {

    /// Thread Safety Coordinator
    private var lock = NSLock()
    private var persistenceStore: UserPersistentRepository

    /// Minimum time between remote fetches. Calls to `update` within this
    /// interval serve the cache instead of hitting the network, unless
    /// forced (e.g. on account change).
    private let minimumRefreshInterval: TimeInterval
    private lazy var operationQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Feature Flags Refresh Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
      }()

    /// The `deviceID` ensures we retain a stable set of Feature Flags between updates. If there are staged rollouts or other dynamic changes
    /// happening server-side we don't want our flags to change on each fetch, so we provide an anonymous ID to manage this.
    public var deviceID: String {
        guard let deviceID = persistenceStore.string(forKey: Constants.DeviceIdKey) else {
            DDLogInfo("🚩 Unable to find existing device ID – generating a new one")
            let newID = UUID().uuidString
            persistenceStore.set(newID, forKey: Constants.DeviceIdKey)
            return newID
        }

        return deviceID
    }

    /// Returns `true` if the store hasn't been updated yet. It uses the
    /// presence of `deviceID` as an indicator of the previous install.
    public var isFreshInstall: Bool {
        persistenceStore.string(forKey: Constants.DeviceIdKey) == nil
    }

    init(persistenceStore: UserPersistentRepository = UserDefaults.standard,
         minimumRefreshInterval: TimeInterval = Constants.defaultMinimumRefreshInterval) {
        self.persistenceStore = persistenceStore
        self.minimumRefreshInterval = minimumRefreshInterval
    }

    /// Fetches remote feature flags from the server.
    /// - Parameter remote: An optional FeatureFlagRemote with a default WordPressComRestApi instance. Inject a FeatureFlagRemote with a different WordPressComRestApi instance
    /// to authenticate with the Remote Feature Flags endpoint – this allows customizing flags server-side on a per-user basis.
    /// - Parameter force: When `true`, bypasses the minimum refresh interval. Use it when the authenticated user changes, since flags are customized per-user server-side.
    /// - Parameter callback: An optional callback that can be used to update UI following the fetch. It is not called on the UI thread.
    public func update(using remote: FeatureFlagRemote = FeatureFlagRemote(wordPressComRestApi: WordPressComRestApi.defaultApi()),
                               force: Bool = false,
                               then callback: FetchCallback? = nil) {
        guard force || shouldFetch else {
            DDLogInfo("🚩 Skipping feature flags update – fetched recently, serving cached flags")
            callback?()
            return
        }

        let refreshOperation = FetchRemoteFeatureFlagsOperation(remote: remote,
                                                                deviceID: deviceID,
                                                                completion: { [weak self] result in
            switch result {
            case .success(let flags):
                self?.cache = flags
                self?.lastFetchedDate = Date()
                callback?()
            case .failure:
                callback?()
            }
        })
        operationQueue.cancelAllOperations()
        operationQueue.addOperation(refreshOperation)
    }

    /// Whether a remote fetch should happen now, given the last fetch time.
    private var shouldFetch: Bool {
        lock.withLock {
            guard let lastFetchedDate = persistenceStore.object(forKey: Constants.LastFetchedDateKey) as? Date else {
                return true
            }
            return Date().timeIntervalSince(lastFetchedDate) >= minimumRefreshInterval
        }
    }

    /// Checks if the local cache has a value for a given `FeatureFlag`
    public func hasValue(for flagKey: String) -> Bool {
        return value(for: flagKey) != nil
    }

    /// Looks up the value for a remote feature flag.
    public func value(for flagKey: String) -> Bool? {
        return cache[flagKey]
    }
}

extension RemoteFeatureFlagStore {
    struct Constants {
        static let DeviceIdKey = "FeatureFlagDeviceId"
        static let CachedFlagsKey = "FeatureFlagStoreCache"
        static let LastFetchedDateKey = "FeatureFlagStoreLastFetchedDate"
        static let defaultMinimumRefreshInterval: TimeInterval = 5 * 60
    }

    typealias FetchCallback = () -> Void

    /// The last time the flags were successfully fetched from the server.
    private var lastFetchedDate: Date? {
        get {
            lock.withLock {
                persistenceStore.object(forKey: Constants.LastFetchedDateKey) as? Date
            }
        }
        set {
            lock.withLock {
                persistenceStore.set(newValue, forKey: Constants.LastFetchedDateKey)
            }
        }
    }

    /// The local cache stores feature flags between runs so that the most recently fetched set are ready to go as soon as this object is instantiated.
    private var cache: [String: Bool] {
        get {
            lock.withLock {
                persistenceStore.dictionary(forKey: Constants.CachedFlagsKey) as? [String: Bool] ?? [:]
            }
        }
        set {
            lock.withLock {
                persistenceStore.set(newValue, forKey: Constants.CachedFlagsKey)
            }
        }
    }
}

fileprivate final class FetchRemoteFeatureFlagsOperation: AsyncOperation, @unchecked Sendable {
    private let remote: FeatureFlagRemote
    private let deviceID: String
    private let completion: OperationCompletionHandler

    typealias OperationCompletionHandler = (Result<[String: Bool], Error>) -> ()

    enum OperationError: Error {
        case operationCanceled
    }

    init(remote: FeatureFlagRemote, deviceID: String, completion: @escaping OperationCompletionHandler) {
        self.remote = remote
        self.deviceID = deviceID
        self.completion = completion
        super.init()
    }

    override func main() {
        DDLogInfo("🚩 Updating Remote Feature Flags with Device ID: \(deviceID)")
        remote.getRemoteFeatureFlags(forDeviceId: deviceID) { [weak self] result in
            if self?.isCancelled == true {
                self?.state = .isFinished
                DDLogInfo("🚩 Feature flags update operation canceled")
                self?.completion(.failure(OperationError.operationCanceled))
                return
            }
            switch result {
                case .success(let flags):
                    DDLogInfo("🚩 Successfully updated local feature flags: \(flags.dictionaryValue)")
                    self?.completion(.success(flags.dictionaryValue))
                case .failure(let error):
                    DDLogError("🚩 Unable to update Feature Flag Store: \(error.localizedDescription)")
                    self?.completion(.failure(error))
            }
            self?.state = .isFinished
        }
    }
}
