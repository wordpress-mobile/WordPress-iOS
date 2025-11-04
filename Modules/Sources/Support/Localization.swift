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
}
