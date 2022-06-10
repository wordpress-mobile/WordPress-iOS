import Foundation

struct FeatureHighlightStore {
    private enum Keys {
        static let didUserDismissTooltipKey = "did-user-dismiss-tooltip-key"
        static let followConversationTooltipCounterKey = "follow-conversation-tooltip-counter"
    }

    @UserDefault(Keys.didUserDismissTooltipKey, defaultValue: true)
    static var didDismissTooltip: Bool

    @UserDefault(Keys.followConversationTooltipCounterKey, defaultValue: 0)
    static var followConversationTooltipCounter: Int

    /// Tooltip will only be shown 3 times if the user never interacts with it.
    static var shouldShowTooltip: Bool {
        followConversationTooltipCounter < 3 || !didDismissTooltip
    }
}
