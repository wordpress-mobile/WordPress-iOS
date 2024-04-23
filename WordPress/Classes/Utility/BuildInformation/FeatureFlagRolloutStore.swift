import Foundation

// Protocol allows easier unit testing, so we can implement mock
// feature flags to use in test cases.
//
protocol RolloutConfigurableFlag: CustomStringConvertible {
    var rolloutPercentage: Int? { get }
}

/// Used to configure rollout groups for feature flags
///
struct FeatureFlagRolloutStore {
    private let store: KeyValueDatabase

    init(store: KeyValueDatabase = UserDefaults.standard) {
        self.store = store
    }

    private func key(for featureFlag: RolloutConfigurableFlag) -> String {
        return "ff-rollout-group-\(String(describing: featureFlag))"
    }

    /// Returns `true` if the assigned group is included in the specificed rollout.
    ///
    func isRolloutEnabled(for featureFlag: RolloutConfigurableFlag) -> Bool {
        guard let rolloutPercentage = featureFlag.rolloutPercentage else {
            return false
        }
        assert(rolloutPercentage >= 1 && rolloutPercentage <= 100, "Value must be between 1 and 100 inclusive")
        let rolloutThreshold = rolloutPercentage * Constants.multiplier
        return (1..<rolloutThreshold).contains(rolloutGroup(for: featureFlag))
    }

    /// Returns the assigned rollout group for the specified feature flag.
    /// If the feature flag hasn't been assigned to a rollout group yet, assigns the flag to a group.
    ///
    private func rolloutGroup(for featureFlag: RolloutConfigurableFlag) -> Int {
        let key = key(for: featureFlag)
        if let value = store.object(forKey: key) as? Int {
            return value
        }
        let group = Int.random(in: 0..<Constants.groupSize)
        store.set(group, forKey: key)
        return group
    }
}

private enum Constants {
    static let groupSize = 100 * multiplier
    static let multiplier = 10
}
