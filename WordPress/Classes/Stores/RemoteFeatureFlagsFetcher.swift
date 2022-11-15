import Foundation
import WordPressKit

class RemoteFeatureFlagsFetcher {

    typealias FetchCallback = () -> Void
    private let store: RemoteFeatureFlagStore

    init(store: RemoteFeatureFlagStore = RemoteFeatureFlagStore()) {
        self.store = store
    }

    /// Fetches remote feature flags from the server.
    /// - Parameter remote: An optional FeatureFlagRemote with a default WordPressComRestApi instance. Inject a FeatureFlagRemote with a different WordPressComRestApi instance
    /// to authenticate with the Remote Feature Flags endpoint – this allows customizing flags server-side on a per-user basis.
    /// - Parameter callback: An optional callback that can be used to update UI following the fetch. It is not called on the UI thread.
    public func update(using remote: FeatureFlagRemote = FeatureFlagRemote(wordPressComRestApi: WordPressComRestApi.defaultApi()),
                               then callback: FetchCallback? = nil) {
        remote.getRemoteFeatureFlags(forDeviceId: store.deviceID) { [weak self] result in
            switch result {
                case .success(let flags):
                    self?.store.cache = flags.dictionaryValue
                    DDLogInfo("🚩 Successfully updated local feature flags: \(flags)")
                    callback?()
                case .failure(let error):
                    DDLogError("🚩 Unable to update Feature Flag Store: \(error.localizedDescription)")
            }
        }
    }
}
