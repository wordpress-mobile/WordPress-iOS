import Foundation
import WordPressShared

// Protocol allows easier unit testing, so we can implement mock
// feature flags to use in test cases.
//
protocol RolloutConfigurableFlag: CustomStringConvertible {
    var rolloutPercentage: Double? { get }
}

/// Used to determine if a feature flag should be enabled, depending on the specified rollout percentage.
///
struct FeatureFlagRolloutStore {
    private let store: KeyValueDatabase

    init(store: KeyValueDatabase = UserDefaults.standard) {
        self.store = store
    }

    /// Returns `true` if the specified feature flag can be rolled out.
    ///
    func isRolloutEnabled(for featureFlag: RolloutConfigurableFlag) -> Bool {
        guard let rolloutPercentage = featureFlag.rolloutPercentage else {
            return false
        }
        assert((0.0..<1.0).contains(rolloutPercentage), "Rollout percentage value must be between 0.0 and 1.0")
        let rolloutThreshold = Int(rolloutPercentage * 100) * Constants.multiplier
        return (1..<rolloutThreshold).contains(rolloutGroup)
    }

    /// Returns the assigned rollout group.
    /// If a rollout group hasn't been assigned yet, assigns a group.
    ///
    private var rolloutGroup: Int {
        if let value = store.object(forKey: Constants.rolloutGroupKey) as? Int {
            return value
        }
        let group = Int.random(in: 0..<Constants.groupSize)
        store.set(group, forKey: Constants.rolloutGroupKey)
        return group
    }
}

private enum Constants {
    static let rolloutGroupKey = "ff-rollout-group-key"
    static let groupSize = 100 * multiplier
    static let multiplier = 10
}
