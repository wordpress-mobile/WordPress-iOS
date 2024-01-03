import Foundation
import WordPressKit

fileprivate extension DispatchQueue {
    static let remoteFeatureFlagStoreQueue = DispatchQueue(label: "remote-feature-flag-store-queue")
}

class RemoteFeatureFlagStore {

    /// Thread Safety Coordinator
    private var queue: DispatchQueue
    private var persistenceStore: UserPersistentRepository
    private lazy var operationQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Feature Flags Refresh Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
      }()

    /// The `deviceID` ensures we retain a stable set of Feature Flags between updates. If there are staged rollouts or other dynamic changes
    /// happening server-side we don't want out flags to change on each fetch, so we provide an anonymous ID to manage this.
    public var deviceID: String {
        guard let deviceID = persistenceStore.string(forKey: Constants.DeviceIdKey) else {
            DDLogInfo("🚩 Unable to find existing device ID – generating a new one")
            let newID = UUID().uuidString
            persistenceStore.set(newID, forKey: Constants.DeviceIdKey)
            return newID
        }

        return deviceID
    }

    init(queue: DispatchQueue = .remoteFeatureFlagStoreQueue,
                 persistenceStore: UserPersistentRepository = UserDefaults.standard) {
        self.queue = queue
        self.persistenceStore = persistenceStore
    }

    /// Fetches remote feature flags from the server.
    /// - Parameter remote: An optional FeatureFlagRemote with a default WordPressComRestApi instance. Inject a FeatureFlagRemote with a different WordPressComRestApi instance
    /// to authenticate with the Remote Feature Flags endpoint – this allows customizing flags server-side on a per-user basis.
    /// - Parameter callback: An optional callback that can be used to update UI following the fetch. It is not called on the UI thread.
    public func update(using remote: FeatureFlagRemote = FeatureFlagRemote(wordPressComRestApi: WordPressComRestApi.defaultApi()),
                               then callback: FetchCallback? = nil) {
        let refreshOperation = FetchRemoteFeatureFlagsOperation(remote: remote,
                                                                deviceID: deviceID,
                                                                completion: { [weak self] result in
            switch result {
            case .success(let flags):
                self?.cache = flags
                callback?()
            case .failure:
                callback?()
            }
        })
        operationQueue.cancelAllOperations()
        operationQueue.addOperation(refreshOperation)
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
    }

    typealias FetchCallback = () -> Void

    /// The local cache stores feature flags between runs so that the most recently fetched set are ready to go as soon as this object is instantiated.
    private var cache: [String: Bool] {
        get {
            // Read from the cache in a thread-safe way
            queue.sync {
                persistenceStore.dictionary(forKey: Constants.CachedFlagsKey) as? [String: Bool] ?? [:]
            }
        }
        set {
            // Write to the cache in a thread-safe way.
            self.queue.sync {
                persistenceStore.set(newValue, forKey: Constants.CachedFlagsKey)
            }
        }
    }
}

fileprivate final class FetchRemoteFeatureFlagsOperation: AsyncOperation {
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
