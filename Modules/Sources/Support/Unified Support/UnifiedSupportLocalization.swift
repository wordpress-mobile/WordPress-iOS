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

    // MARK: - Conversation

    static let newConversation = NSLocalizedString(
        "com.jetpack.support.unified.newConversation",
        value: "New conversation",
        comment: "Button that starts a new support conversation with the AI Assistant."
    )
    static let startConversation = NSLocalizedString(
        "com.jetpack.support.unified.startConversation",
        value: "Start Conversation",
        comment: "Button that starts the user's first support conversation."
    )
    static let loadingConversation = NSLocalizedString(
        "com.jetpack.support.unified.conversation.loading",
        value: "Loading conversation…",
        comment: "Shown while a support conversation is loading."
    )
    static let messagePlaceholder = NSLocalizedString(
        "com.jetpack.support.unified.conversation.messagePlaceholder",
        value: "Type a message…",
        comment: "Placeholder of the field used to write a message to the AI Assistant."
    )
    static let sendMessage = NSLocalizedString(
        "com.jetpack.support.unified.conversation.send",
        value: "Send",
        comment: "Button that sends the message written for the AI Assistant."
    )
    static let assistantIsTyping = NSLocalizedString(
        "com.jetpack.support.unified.conversation.typing",
        value: "The AI Assistant is typing",
        comment: "Announced while waiting for the AI Assistant to answer."
    )
    static let lastUpdated = NSLocalizedString(
        "com.jetpack.support.unified.conversation.lastUpdated",
        value: "Last updated %1$@",
        comment: "Time a support conversation was last updated. %1$@ is a time, like '2 days ago'."
    )
    static let transferredToHumanSupport = NSLocalizedString(
        "com.jetpack.support.unified.conversation.transferred",
        value: "Transferred to human support",
        comment: "Shown in a conversation where the AI Assistant handed the question to the support team."
    )
    static let conversationClosed = NSLocalizedString(
        "com.jetpack.support.unified.conversation.closed",
        value: "This conversation is closed. You can no longer reply to it.",
        comment: "Shown at the end of a support conversation that can't accept replies."
    )
    static let attachmentMatchScore = NSLocalizedString(
        "com.jetpack.support.unified.conversation.attachment.matchScore",
        value: "%1$d%% match",
        comment: "How closely a page matches the AI Assistant's answer. %1$d is a percentage, like 87."
    )
    static let relatedLinks = NSLocalizedString(
        "com.jetpack.support.unified.conversation.attachment.related",
        value: "Related:",
        comment: "Introduces the pages the AI Assistant used to answer, listed under its answer."
    )
    static let openLink = NSLocalizedString(
        "com.jetpack.support.unified.conversation.attachment.openLink",
        value: "Open link: %1$@",
        comment: "Accessibility label of a page the AI Assistant used for its answer. %1$@ is the page title."
    )
    static let loadingAttachment = NSLocalizedString(
        "com.jetpack.support.unified.conversation.attachment.loading",
        value: "Loading attachment…",
        comment: "Shown while an attachment of a support message is loading."
    )

    // MARK: - Reply form

    static let message = NSLocalizedString(
        "com.jetpack.support.unified.reply.message",
        value: "Message",
        comment: "Title of the field where the user writes a reply to the support team."
    )
    static let send = NSLocalizedString(
        "com.jetpack.support.unified.reply.send",
        value: "Send",
        comment: "Button that sends the reply written for the support team."
    )
    static let cancel = NSLocalizedString(
        "com.jetpack.support.unified.reply.cancel",
        value: "Cancel",
        comment: "Button that closes the form used to reply to the support team."
    )
    static let ok = NSLocalizedString(
        "com.jetpack.support.unified.reply.ok",
        value: "OK",
        comment: "Button that dismisses a message about a reply that couldn't be sent."
    )
    static let optional = NSLocalizedString(
        "com.jetpack.support.unified.reply.optional",
        value: "Optional",
        comment: "Marks a part of the reply form the user doesn't have to fill in."
    )
    static let sendingReply = NSLocalizedString(
        "com.jetpack.support.unified.reply.sending",
        value: "Sending…",
        comment: "Shown on the reply button while the reply is being sent to the support team."
    )
    static let replySent = NSLocalizedString(
        "com.jetpack.support.unified.reply.sent",
        value: "Your reply has been sent. Check your email for updates.",
        comment: "Shown after a reply to the support team has been sent."
    )
    static let replyFailedTitle = NSLocalizedString(
        "com.jetpack.support.unified.reply.failed.title",
        value: "Your reply wasn't sent",
        comment: "Title of the message shown when a reply to the support team couldn't be sent."
    )
    static let replyFailedTryAgain = NSLocalizedString(
        "com.jetpack.support.unified.reply.failed.tryAgain",
        value: "Try Again",
        comment: "Button that opens the reply form again after a reply couldn't be sent."
    )
    static let discardReplyTitle = NSLocalizedString(
        "com.jetpack.support.unified.reply.discard.title",
        value: "Discard this reply?",
        comment: "Title of the confirmation shown when closing the reply form with an unsent reply."
    )
    static let discardReplyMessage = NSLocalizedString(
        "com.jetpack.support.unified.reply.discard.message",
        value: "Your message and its attachments will be lost.",
        comment: "Explains what is lost by closing the reply form with an unsent reply."
    )
    static let discardReply = NSLocalizedString(
        "com.jetpack.support.unified.reply.discard.confirm",
        value: "Discard",
        comment: "Button that throws away an unsent reply to the support team."
    )
    static let keepWriting = NSLocalizedString(
        "com.jetpack.support.unified.reply.discard.cancel",
        value: "Keep Writing",
        comment: "Button that goes back to the reply form instead of throwing away an unsent reply."
    )

    // MARK: - Reply attachments

    static let attachments = NSLocalizedString(
        "com.jetpack.support.unified.reply.attachments",
        value: "Attachments",
        comment: "Title of the part of the reply form where images and videos are attached."
    )
    static let attachmentsDescription = NSLocalizedString(
        "com.jetpack.support.unified.reply.attachments.description",
        value: "Add images or videos that show the problem.",
        comment: "Explains what to attach to a reply to the support team."
    )
    static let addAttachments = NSLocalizedString(
        "com.jetpack.support.unified.reply.attachments.add",
        value: "Add Images or Videos",
        comment: "Button that picks the images and videos to send with a reply."
    )
    static let addMoreAttachments = NSLocalizedString(
        "com.jetpack.support.unified.reply.attachments.addMore",
        value: "Add More",
        comment: "Button that picks more images and videos to send with a reply."
    )
    static let attachmentsPartial = NSLocalizedString(
        "com.jetpack.support.unified.reply.attachments.partial",
        value: "Max size reached. Only %1$d of %2$d files will be sent",
        comment: "Says how many attachments fit in a reply. %1$d is how many are sent, %2$d how many were picked."
    )
    static let attachmentTooLarge = NSLocalizedString(
        "com.jetpack.support.unified.reply.attachments.tooLarge.one",
        value: "This file is too large to send.",
        comment: "Shown when the only file picked for a reply is over the upload limit on its own."
    )
    static let attachmentsTooLarge = NSLocalizedString(
        "com.jetpack.support.unified.reply.attachments.tooLarge.other",
        value: "These files are too large to send.",
        comment: "Shown when every file picked for a reply is over the upload limit on its own."
    )
    static let attachmentsFailedTitle = NSLocalizedString(
        "com.jetpack.support.unified.reply.attachments.failed",
        value: "Unable to attach the file",
        comment: "Title of the message shown when a picked image or video can't be attached to a reply."
    )
    static let removeAttachment = NSLocalizedString(
        "com.jetpack.support.unified.reply.attachments.remove",
        value: "Remove %1$@",
        comment: "Button that takes a file off a reply. %1$@ is the file name."
    )
}
