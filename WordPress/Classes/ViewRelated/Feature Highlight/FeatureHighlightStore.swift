import Foundation

struct FeatureHighlightStore {
    private enum Keys {
        static let didUserDismissTooltipKey = "did-user-dismiss-tooltip-key"
        static let followConversationTooltipCounterKey = "follow-conversation-tooltip-counter"
    }

    private let userStore: UserPersistentRepository

    init(userStore: UserPersistentRepository = UserPersistentStoreFactory.instance()) {
        self.userStore = userStore
    }

    var didDismissTooltip: Bool {
        get {
            return userStore.bool(forKey: Keys.didUserDismissTooltipKey)
        }
        set {
            userStore.set(newValue, forKey: Keys.didUserDismissTooltipKey)
        }
    }

    var followConversationTooltipCounter: Int {
        get {
            return userStore.integer(forKey: Keys.followConversationTooltipCounterKey)
        }
        set {
            userStore.set(newValue, forKey: Keys.followConversationTooltipCounterKey)
        }
    }

    /// Tooltip will only be shown 3 times if the user never interacts with it.
    var shouldShowTooltip: Bool {
        followConversationTooltipCounter < 3 && !didDismissTooltip
    }
}
