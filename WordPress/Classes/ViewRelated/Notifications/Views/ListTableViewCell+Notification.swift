/// Encapsulates logic that configures `ListTableViewCell` with `Notification` models.
///
extension ListTableViewCell {
    /// Configures the cell based on the provided `Notification` object.
    func configureWithNotification(_ notification: Notification) {
        // indicator view
        indicatorColor = Style.unreadIndicatorColor
        showsIndicator = !notification.read

        // handle indicators for unapproved comments, with unread indicators taking priority.
        // only show unapproved indicators for read notifications.
        if notification.kind == .comment, notification.read {
            indicatorColor = WPStyleGuide.Comments.pendingIndicatorColor
            showsIndicator = notification.isUnapprovedComment
        }

        // avatar image
        configureImage(with: notification.iconURL)

        // title text
        attributedTitleText = notification.renderSubject()

        // snippet text
        snippetText = notification.renderSnippet()?.string ?? String()
    }
}

// MARK: - Constants

private extension ListTableViewCell {
    typealias Style = WPStyleGuide.Notifications
}
