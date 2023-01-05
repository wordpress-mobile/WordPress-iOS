import Foundation
import WordPressKit

fileprivate extension DispatchQueue {
    static let remoteFeatureFlagStoreQueue = DispatchQueue(label: "remote-feature-flag-store-queue")
}

class RemoteFeatureFlagStore {

    /// Thread Safety Coordinator
    private var queue: DispatchQueue
    private var persistenceStore: UserPersistentRepository

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
        DDLogInfo("🚩 Updating Remote Feature Flags with Device ID: \(deviceID)")
        remote.getRemoteFeatureFlags(forDeviceId: deviceID) { [weak self] result in
            switch result {
                case .success(let flags):
                    self?.cache = flags.dictionaryValue
                    DDLogInfo("🚩 Successfully updated local feature flags: \(flags)")
                    callback?()
                case .failure(let error):
                    DDLogError("🚩 Unable to update Feature Flag Store: \(error.localizedDescription)")
            }
        }
    }

    /// Checks if the local cache has a value for a given `FeatureFlag`
    public func hasValue(for flag: OverrideableFlag) -> Bool {
        guard let remoteKey = flag.remoteKey else {
            return false
        }

        return cache[remoteKey] != nil
    }

    /// Looks up the value for a remote feature flag.
    ///
    /// If the flag exists in the local cache, the current value will be returned.  If the flag does not exist in the local cache, the compile-time default will be returned.
    /// - Parameters:
    ///     - flag: The `FeatureFlag` object associated with a remote feature flag
    public func value(for flag: OverrideableFlag) -> Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: flag) {
            return overriddenValue
        }
        guard
            let remoteKey = flag.remoteKey, // Not all flags contain a remote key, since they may not use remote feature flagging
            let value = cache[remoteKey]    // The value may not be in the cache if this is the first run
            else {
                DDLogInfo("🚩 Unable to resolve remote feature flag: \(flag.description). Returning compile-time default.")
                return flag.enabled
        }

        return value
    }
}

extension RemoteFeatureFlagStore {
    struct Constants {
        static let DeviceIdKey = "FeatureFlagDeviceId"
        static let CachedFlagsKey = "FeatureFlagStoreCache"
    }

    typealias FetchCallback = () -> Void

    /// The `deviceID` ensures we retain a stable set of Feature Flags between updates. If there are staged rollouts or other dynamic changes
    /// happening server-side we don't want out flags to change on each fetch, so we provide an anonymous ID to manage this.
    private var deviceID: String {
        guard let deviceID = persistenceStore.string(forKey: Constants.DeviceIdKey) else {
            DDLogInfo("🚩 Unable to find existing device ID – generating a new one")
            let newID = UUID().uuidString
            persistenceStore.set(newID, forKey: Constants.DeviceIdKey)
            return newID
        }

        return deviceID
    }

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
