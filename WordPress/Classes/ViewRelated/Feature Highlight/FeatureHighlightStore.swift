import Foundation

struct FeatureHighlightStore {
    private enum Keys {
        static let didUserDismissTooltipKey = "did-user-dismiss-tooltip-key"
        static let followConversationTooltipCounterKey = "follow-conversation-tooltip-counter"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    var didDismissTooltip: Bool {
        get {
            return userDefaults.bool(forKey: Keys.didUserDismissTooltipKey)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.didUserDismissTooltipKey)
        }
    }

    var followConversationTooltipCounter: Int {
        get {
            return userDefaults.integer(forKey: Keys.followConversationTooltipCounterKey)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.followConversationTooltipCounterKey)
        }
    }

    /// Tooltip will only be shown 3 times if the user never interacts with it.
    var shouldShowTooltip: Bool {
        followConversationTooltipCounter < 3 && !didDismissTooltip
    }
}
