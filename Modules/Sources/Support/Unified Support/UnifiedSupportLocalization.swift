import Foundation

enum UnifiedSupportLocalization {

    // MARK: - Conversation statuses

    static let statusAIAssistant = NSLocalizedString(
        "com.jetpack.support.unified.status.aiAssistant",
        value: "AI Assistant",
        comment: "Badge on a support conversation that is handled by the AI Assistant."
    )
    static let statusOngoing = NSLocalizedString(
        "com.jetpack.support.unified.status.ongoing",
        value: "Ongoing",
        comment: "Badge on a support conversation that a Happiness Engineer is handling."
    )
    static let statusSolved = NSLocalizedString(
        "com.jetpack.support.unified.status.solved",
        value: "Solved",
        comment: "Badge on a support conversation that has been solved."
    )
    static let statusClosed = NSLocalizedString(
        "com.jetpack.support.unified.status.closed",
        value: "Closed",
        comment: "Badge on a support conversation that is closed and can no longer be replied to."
    )
    static let statusUnknown = NSLocalizedString(
        "com.jetpack.support.unified.status.unknown",
        value: "Unknown",
        comment: "Badge on a support conversation whose status is not recognized."
    )

    // MARK: - Reply actions

    static let reply = NSLocalizedString(
        "com.jetpack.support.unified.reply",
        value: "Reply",
        comment: "Button to reply to a support conversation when a Happiness Engineer is waiting for the user's answer."
    )
    static let addMoreInfo = NSLocalizedString(
        "com.jetpack.support.unified.addMoreInfo",
        value: "Add more info",
        comment: "Button to add more information to a support conversation that is waiting for a Happiness Engineer."
    )

    // MARK: - Relative time

    static let justNow = NSLocalizedString(
        "com.jetpack.support.unified.justNow",
        value: "Just now",
        comment: "Time of a support conversation or message that was updated less than a minute ago."
    )

    // MARK: - Conversations list

    static let conversationsTitle = NSLocalizedString(
        "com.jetpack.support.unified.conversations.title",
        value: "Get help",
        comment: "Title of the screen listing the user's support conversations."
    )
    static let loadingConversations = NSLocalizedString(
        "com.jetpack.support.unified.conversations.loading",
        value: "Loading conversations…",
        comment: "Shown while the user's support conversations are loading."
    )
    static let emptyConversationsTitle = NSLocalizedString(
        "com.jetpack.support.unified.conversations.empty.title",
        value: "No conversations yet",
        comment: "Title shown when the user has no support conversations."
    )
    static let emptyConversationsMessage = NSLocalizedString(
        "com.jetpack.support.unified.conversations.empty.message",
        value: "Start a conversation with our support team to get help with your questions.",
        comment: "Message shown when the user has no support conversations."
    )

    // MARK: - Errors

    static let offlineTitle = NSLocalizedString(
        "com.jetpack.support.unified.offline.title",
        value: "No network available",
        comment: "Title shown when support conversations can't be loaded because the device is offline."
    )
    static let offlineMessage = NSLocalizedString(
        "com.jetpack.support.unified.offline.message",
        value: "Check your internet connection and try again.",
        comment: "Message shown when support conversations can't be loaded because the device is offline."
    )
    static let genericErrorTitle = NSLocalizedString(
        "com.jetpack.support.unified.error.title",
        value: "Something went wrong",
        comment: "Title shown when support conversations can't be loaded."
    )
    static let notLoggedInMessage = NSLocalizedString(
        "com.jetpack.support.unified.notLoggedIn.message",
        value: "Log in to WordPress.com to get help from our support team.",
        comment: "Shown when support conversations can't be loaded because the user isn't logged in to WordPress.com."
    )
    static let genericErrorMessage = NSLocalizedString(
        "com.jetpack.support.unified.error.message",
        value: "Something went wrong. Please try again later.",
        comment: "Message shown when a support request fails."
    )
    static let tryAgain = NSLocalizedString(
        "com.jetpack.support.unified.tryAgain",
        value: "Try again",
        comment: "Button to try loading the support conversations again."
    )
}
