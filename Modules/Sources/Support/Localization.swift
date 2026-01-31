import Foundation

enum Localization {
    // MARK: - Shared Constants (used by multiple files)

    static let optional = NSLocalizedString(
        "com.jetpack.support.optional",
        value: "(Optional)",
        comment: "Text indicating a field is optional"
    )
    static let message = NSLocalizedString(
        "com.jetpack.support.message",
        value: "Message",
        comment: "Section header for message text input"
    )
    static let reply = NSLocalizedString(
        "com.jetpack.support.reply",
        value: "Reply",
        comment: "Navigation title for replying to a support conversation"
    )

    // MARK: - SupportForm.swift

    static let title = NSLocalizedString(
        "com.jetpack.support.title",
        value: "Contact Support",
        comment: "Title of the view for contacting support."
    )
    static let iNeedHelp = NSLocalizedString(
        "com.jetpack.support.iNeedHelp",
        value: "I need help with",
        comment: "Text on the support form to refer to what area the user has problem with."
    )
    static let contactInformation = NSLocalizedString(
        "com.jetpack.support.contactInformation",
        value: "Contact Information",
        comment: "Section title for contact information"
    )
    static let issueDetails = NSLocalizedString(
        "com.jetpack.support.issueDetails",
        value: "Issue Details",
        comment: "Section title for issue details"
    )
    static let subject = NSLocalizedString(
        "com.jetpack.support.subject",
        value: "Subject",
        comment: "Subject title on the support form"
    )
    static let subjectPlaceholder = NSLocalizedString(
        "com.jetpack.support.subjectPlaceholder",
        value: "Brief summary of your issue",
        comment: "Placeholder for subject field"
    )
    static let siteAddress = NSLocalizedString(
        "com.jetpack.support.siteAddress",
        value: "Site Address",
        comment: "Site Address title on the support form"
    )
    static let siteAddressPlaceholder = NSLocalizedString(
        "com.jetpack.support.siteAddressPlaceholder",
        value: "https://yoursite.com",
        comment: "Placeholder for site address field"
    )
    static let submitRequest = NSLocalizedString(
        "com.jetpack.support.submitRequest",
        value: "Submit Support Request",
        comment: "Button title to submit a support request."
    )
    static let errorTitle = NSLocalizedString(
        "com.jetpack.support.errorTitle",
        value: "Error",
        comment: "Title for error alerts"
    )
    static let gotIt = NSLocalizedString(
        "com.jetpack.support.gotIt",
        value: "Got It",
        comment: "Button to dismiss alerts."
    )
    static let supportRequestSent = NSLocalizedString(
        "com.jetpack.support.supportRequestSent",
        value: "Request Sent!",
        comment: "Title for the alert after the support request is created."
    )
    static let supportRequestSentMessage = NSLocalizedString(
        "com.jetpack.support.supportRequestSentMessage",
        value: "Your support request has been sent successfully. We will reply via email as quickly as we can.",
        comment: "Message for the alert after the support request is created."
    )

    // MARK: - ScreenshotPicker.swift

    static let screenshots = NSLocalizedString(
        "com.jetpack.support.screenshots",
        value: "Screenshots",
        comment: "Label for screenshots section"
    )
    static let screenshotsDescription = NSLocalizedString(
        "com.jetpack.support.screenshotsDescription",
        value: "Adding screenshots can help us understand and resolve your issue faster.",
        comment: "Description for screenshots section"
    )
    static let addScreenshots = NSLocalizedString(
        "com.jetpack.support.addScreenshots",
        value: "Add Screenshots",
        comment: "Button to add screenshots"
    )
    static let addMoreScreenshots = NSLocalizedString(
        "com.jetpack.support.addMoreScreenshots",
        value: "Add More Screenshots",
        comment: "Button to add more screenshots"
    )

    // MARK: - ApplicationLogPicker.swift

    static let applicationLogs = NSLocalizedString(
        "com.jetpack.support.applicationLogs",
        value: "Application Logs",
        comment: "Header for application logs section"
    )
    static let applicationLogsDescription = NSLocalizedString(
        "com.jetpack.support.applicationLogsDescription",
        value: "Including logs can help our team investigate issues. Logs may contain recent app activity.",
        comment: "Description explaining why including logs is helpful"
    )
    static let logFilesToUpload = NSLocalizedString(
        "com.jetpack.support.logFilesToUpload",
        value: "The following log files will be uploaded:",
        comment: "Text indicating which log files will be included in the support request"
    )
    static let unableToLoadApplicationLogs = NSLocalizedString(
        "com.jetpack.support.unableToLoadApplicationLogs",
        value: "Unable to load application logs",
        comment: "Error message when application logs cannot be loaded"
    )
    static let includeApplicationLogs = NSLocalizedString(
        "com.jetpack.support.includeApplicationLogs",
        value: "Include application logs",
        comment: "Toggle label to include application logs in the support request"
    )

    // MARK: - SupportConversationListView.swift

    static let supportConversations = NSLocalizedString(
        "com.jetpack.support.supportConversations",
        value: "Support Conversations",
        comment: "Navigation title for the support conversations list"
    )
    static let loadingConversations = NSLocalizedString(
        "com.jetpack.support.loadingConversations",
        value: "Loading Conversations",
        comment: "Progress text while loading support conversations"
    )
    static let errorLoadingSupportConversations = NSLocalizedString(
        "com.jetpack.support.errorLoadingSupportConversations",
        value: "Error loading support conversations",
        comment: "Error message when support conversations fail to load"
    )

    // MARK: - SupportConversationView.swift

    static let loadingMessages = NSLocalizedString(
        "com.jetpack.support.loadingMessages",
        value: "Loading Messages",
        comment: "Progress text while loading conversation messages"
    )
    static let unableToDisplayConversation = NSLocalizedString(
        "com.jetpack.support.unableToDisplayConversation",
        value: "Unable to display conversation",
        comment: "Error message when conversation cannot be displayed"
    )
    static let messagesCount = NSLocalizedString(
        "com.jetpack.support.messagesCount",
        value: "%d Messages",
        comment: "Format string for number of messages in conversation"
    )
    static let lastUpdated = NSLocalizedString(
        "com.jetpack.support.lastUpdated",
        value: "Last updated %@",
        comment: "Format string for when conversation was last updated"
    )
    static let attachment = NSLocalizedString(
        "com.jetpack.support.attachment",
        value: "Attachment %@",
        comment: "Format string for attachment identifier"
    )
    static let view = NSLocalizedString(
        "com.jetpack.support.view",
        value: "View",
        comment: "Button to view an attachment"
    )

    // MARK: - SupportConversationReplyView.swift

    static let cancel = NSLocalizedString(
        "com.jetpack.support.cancel",
        value: "Cancel",
        comment: "Button to cancel current action"
    )
    static let send = NSLocalizedString(
        "com.jetpack.support.send",
        value: "Send",
        comment: "Button to send a message or reply"
    )
    static let sending = NSLocalizedString(
        "com.jetpack.support.sending",
        value: "Sending",
        comment: "Progress text while sending a message"
    )
    static let sendingMessage = NSLocalizedString(
        "com.jetpack.support.sendingMessage",
        value: "Sending Message",
        comment: "Progress message shown while sending a message"
    )
    static let unableToSendMessage = NSLocalizedString(
        "com.jetpack.support.unableToSendMessage",
        value: "Unable to send Message",
        comment: "Error title when message sending fails"
    )
    static let messageSent = NSLocalizedString(
        "com.jetpack.support.messageSent",
        value: "Message Sent",
        comment: "Success message when reply is sent successfully"
    )
    static let discardChanges = NSLocalizedString(
        "com.jetpack.support.discardChanges",
        value: "Discard Changes",
        comment: "Button to discard changes in a draft message"
    )
    static let continueWriting = NSLocalizedString(
        "com.jetpack.support.continueWriting",
        value: "Continue Writing",
        comment: "Button to continue editing a message"
    )
    static let confirmCancelMessage = NSLocalizedString(
        "com.jetpack.support.confirmCancelMessage",
        value: "Are you sure you want to cancel this message? You'll lose any data you've entered",
        comment: "Confirmation message when canceling a draft"
    )
    static let confirmCancellation = NSLocalizedString(
        "com.jetpack.support.confirmCancellation",
        value: "Confirm Cancellation",
        comment: "Title for alert confirming cancellation"
    )
    static let emailNotice = NSLocalizedString(
        "com.jetpack.support.emailNotice",
        value: "We'll email you at this address.",
        comment: "Notice explaining where support will send email responses"
    )

    // MARK: - DiagnosticsView.swift

    static let diagnosticsTitle = NSLocalizedString(
        "com.jetpack.support.diagnosticsTitle",
        value: "Diagnostics",
        comment: "Navigation title for diagnostics screen"
    )
    static let diagnosticsDescription = NSLocalizedString(
        "com.jetpack.support.diagnosticsDescription",
        value: "Run common maintenance and troubleshooting tasks.",
        comment: "Description text for diagnostics screen"
    )

    // MARK: - EmptyDiskCacheView.swift

    static let clearDiskCache = NSLocalizedString(
        "com.jetpack.support.clearDiskCache",
        value: "Clear Disk Cache",
        comment: "Button to clear disk cache"
    )
    static let clearing = NSLocalizedString(
        "com.jetpack.support.clearing",
        value: "Clearing…",
        comment: "Progress text while clearing cache"
    )
    static let cacheIsEmpty = NSLocalizedString(
        "com.jetpack.support.cacheIsEmpty",
        value: "Cache is empty",
        comment: "Message shown when cache has no files"
    )
    static let cacheFiles = NSLocalizedString(
        "com.jetpack.support.cacheFiles",
        value: "%1$d cached files (%2$@)",
        comment: "Format string for cache file count and size. %1$d is the number of files, %2$@ is the formatted size. The system will pluralize 'files' based on the number – please specify it as the largest plural value"
    )
    static let clearDiskCacheDescription = NSLocalizedString(
        "com.jetpack.support.clearDiskCacheDescription",
        value: "Remove temporary files to free up space or resolve problems.",
        comment: "Description explaining the purpose of clearing disk cache"
    )
    static let loadingDiskUsage = NSLocalizedString(
        "com.jetpack.support.loadingDiskUsage",
        value: "Loading Disk Usage",
        comment: "Progress message while loading disk usage information"
    )
    static let working = NSLocalizedString(
        "com.jetpack.support.working",
        value: "Working",
        comment: "Progress message shown during cache clearing operation"
    )
    static let complete = NSLocalizedString(
        "com.jetpack.support.complete",
        value: "Complete",
        comment: "Message shown when cache clearing is complete"
    )

    // MARK: - ActivityLogListView.swift

    static let applicationLogsTitle = NSLocalizedString(
        "com.jetpack.support.applicationLogsTitle",
        value: "Application Logs",
        comment: "Navigation title for application logs screen"
    )

    // MARK: - ActivityLogDetailView.swift

    static let loadingLogContent = NSLocalizedString(
        "com.jetpack.support.loadingLogContent",
        value: "Loading log content...",
        comment: "Progress message while loading application log content"
    )
    static let confirmDeleteAllLogs = NSLocalizedString(
        "com.jetpack.support.confirmDeleteAllLogs",
        value: "Are you sure you want to delete all logs?",
        comment: "Confirmation dialog title when deleting all logs"
    )
    static let deleteAllLogs = NSLocalizedString(
        "com.jetpack.support.deleteAllLogs",
        value: "Delete all Logs",
        comment: "Button to delete all log files"
    )
    static let cannotRecoverLogs = NSLocalizedString(
        "com.jetpack.support.cannotRecoverLogs",
        value: "You won't be able to get them back.",
        comment: "Warning message that deleted logs cannot be recovered"
    )
    static let errorLoadingLogs = NSLocalizedString(
        "com.jetpack.support.errorLoadingLogs",
        value: "Error loading logs",
        comment: "Error title when logs fail to load"
    )
    static let unableToDeleteLogs = NSLocalizedString(
        "com.jetpack.support.unableToDeleteLogs",
        value: "Unable to delete logs",
        comment: "Error title when log deletion fails"
    )
    static let logFilesByDate = NSLocalizedString(
        "com.jetpack.support.logFilesByDate",
        value: "Log files by created date",
        comment: "Section header for log files sorted by date"
    )
    static let logRetentionNotice = NSLocalizedString(
        "com.jetpack.support.logRetentionNotice",
        value: "Up to seven days worth of logs are saved.",
        comment: "Footer text explaining log retention policy"
    )
    static let clearAllActivityLogs = NSLocalizedString(
        "com.jetpack.support.clearAllActivityLogs",
        value: "Clear All Activity Logs",
        comment: "Button to clear all activity logs"
    )
    static let noLogsFound = NSLocalizedString(
        "com.jetpack.support.noLogsFound",
        value: "No Logs Found",
        comment: "Label shown when no log files are available"
    )
    static let noLogsAvailable = NSLocalizedString(
        "com.jetpack.support.noLogsAvailable",
        value: "There are no activity logs available",
        comment: "Description shown when no log files are available"
    )
    static let loadingLogs = NSLocalizedString(
        "com.jetpack.support.loadingLogs",
        value: "Loading logs...",
        comment: "Progress message while loading log files"
    )
    static let extensiveLogging = NSLocalizedString(
        "com.jetpack.support.extensiveLogging",
        value: "Extensive Logging",
        comment: "Toggle title for enabling extensive logging"
    )
    static let extensiveLogs = NSLocalizedString(
        "com.jetpack.support.extensiveLogs",
        value: "Extensive Logs",
        comment: "Link title to view extensive logs"
    )
    static let extensiveLoggingAlertTitle = NSLocalizedString(
        "com.jetpack.support.extensiveLoggingAlertTitle",
        value: "Enable Extensive Logging?",
        comment: "Alert title when confirming extensive logging activation"
    )
    static let extensiveLoggingAlertMessage = NSLocalizedString(
        "com.jetpack.support.extensiveLoggingAlertMessage",
        value: "This helps with troubleshooting but may impact performance. You can turn it off anytime.",
        comment: "Alert message explaining extensive logging helps with troubleshooting but may impact performance"
    )
    static let enable = NSLocalizedString(
        "com.jetpack.support.extensiveLogging.enable",
        value: "Enable",
        comment: "Button title to enable extensive logging"
    )

    // MARK: - ActivityLogSharingView.swift

    static let share = NSLocalizedString(
        "com.jetpack.support.share",
        value: "Share",
        comment: "Button to share content"
    )
    static let shareActivityLog = NSLocalizedString(
        "com.jetpack.support.shareActivityLog",
        value: "Share Activity Log",
        comment: "Navigation title for sharing activity log"
    )
    static let sharingWithSupport = NSLocalizedString(
        "com.jetpack.support.sharingWithSupport",
        value: "Sharing with support!",
        comment: "Message shown when sharing log with support"
    )
    static let newSupportTicket = NSLocalizedString(
        "com.jetpack.support.newSupportTicket",
        value: "New Support Ticket",
        comment: "Option to create a new support ticket"
    )
    static let exportAsFile = NSLocalizedString(
        "com.jetpack.support.exportAsFile",
        value: "Export as File",
        comment: "Option to export log as a file"
    )
    static let sendLogsToSupport = NSLocalizedString(
        "com.jetpack.support.sendLogsToSupport",
        value: "Send logs directly to support team",
        comment: "Description for sending logs to support"
    )
    static let saveAsFile = NSLocalizedString(
        "com.jetpack.support.saveAsFile",
        value: "Save as a file to share or store",
        comment: "Description for saving log as a file"
    )

    // MARK: - ConversationListView.swift

    static let conversations = NSLocalizedString(
        "com.jetpack.support.conversations",
        value: "Conversations",
        comment: "Navigation title for bot conversations list"
    )
    static let noConversations = NSLocalizedString(
        "com.jetpack.support.noConversations",
        value: "No Conversations",
        comment: "Label shown when there are no bot conversations"
    )
    static let startNewConversation = NSLocalizedString(
        "com.jetpack.support.startNewConversation",
        value: "Start a new conversation using the button above",
        comment: "Description encouraging user to start a new conversation"
    )
    static let loadingBotConversations = NSLocalizedString(
        "com.jetpack.support.loadingBotConversations",
        value: "Loading Bot Conversations",
        comment: "Progress message while loading bot conversations"
    )
    static let unableToLoadConversations = NSLocalizedString(
        "com.jetpack.support.unableToLoadConversations",
        value: "Unable to load conversations",
        comment: "Error title when bot conversations fail to load"
    )

    // MARK: - ConversationView.swift

    static let openSupportTicket = NSLocalizedString(
        "com.jetpack.support.openSupportTicket",
        value: "Open a Support Ticket",
        comment: "Button to open a support ticket"
    )
    static let loadingBotConversationMessages = NSLocalizedString(
        "com.jetpack.support.loadingBotConversationMessages",
        value: "Loading Messages",
        comment: "Progress message while loading conversation messages"
    )
    static let unableToLoadMessages = NSLocalizedString(
        "com.jetpack.support.unableToLoadMessages",
        value: "Unable to Load Messages",
        comment: "Error title when messages fail to load"
    )

    // MARK: - ConversationBotIntro.swift

    static let botGreeting = NSLocalizedString(
        "com.jetpack.support.botGreeting",
        value: "Howdy %1$@!",
        comment: "Bot greeting message. %1$@ is the user's name"
    )
    static let botIntroduction = NSLocalizedString(
        "com.jetpack.support.botIntroduction",
        value: "I'm your personal AI assistant. I can help with any questions about your site or account.",
        comment: "Bot introduction message explaining its purpose"
    )

    // MARK: - ThinkingView.swift

    static let thinking = NSLocalizedString(
        "com.jetpack.support.thinking",
        value: "Thinking...",
        comment: "Progress message shown while bot is thinking"
    )

    // MARK: - SupportConversationView.swift

    static let conversationEnded = NSLocalizedString(
        "com.jetpack.support.conversationEnded",
        value: "End of conversation. No further replies are possible.",
        comment: "Message shown at end of closed support conversation"
    )

    // MARK: - ScreenshotPicker.swift

    static let attachmentLimit = NSLocalizedString(
        "com.jetpack.support.attachmentLimit",
        value: "Attachment Limit: %1$@ / %2$@",
        comment: "Format string for attachment size limit. %1$@ is current size, %2$@ is maximum size"
    )

    // MARK: - ErrorView.swift

    static let tryAgain = NSLocalizedString(
        "com.jetpack.support.tryAgain",
        value: "Try Again",
        comment: "Button to retry a failed operation"
    )

    // MARK: - AttachmentListView.swift

    static let loadingImage = NSLocalizedString(
        "com.jetpack.support.loadingImage",
        value: "Loading Image",
        comment: "Progress message while loading an image attachment"
    )
    static let loadingVideo = NSLocalizedString(
        "com.jetpack.support.loadingVideo",
        value: "Loading Video",
        comment: "Progress message while loading a video attachment"
    )
    static let unableToDisplayVideo = NSLocalizedString(
        "com.jetpack.support.unableToDisplayVideo",
        value: "Unable to display video",
        comment: "Error title when video cannot be loaded or played"
    )

    // MARK: - OverlayProgressView.swift

    static let loadingLatestContent = NSLocalizedString(
        "com.jetpack.support.loadingLatestContent",
        value: "Loading latest content",
        comment: "Progress message shown in overlay while refreshing content"
    )
}
