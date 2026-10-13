import Foundation

enum Localization {
    // MARK: - Shared Constants (used by multiple files)

    static let cancel = NSLocalizedString(
        "com.jetpack.support.cancel",
        value: "Cancel",
        comment: "Button to cancel current action"
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

    // MARK: - ActivityLogDetailView.swift

    static let loadingLogContent = NSLocalizedString(
        "com.jetpack.support.loadingLogContent",
        value: "Loading log content...",
        comment: "Progress message while loading application log content"
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

    // MARK: - ErrorView.swift

    static let tryAgain = NSLocalizedString(
        "com.jetpack.support.tryAgain",
        value: "Try Again",
        comment: "Button to retry a failed operation"
    )

    // MARK: - SingleVideoView.swift

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
