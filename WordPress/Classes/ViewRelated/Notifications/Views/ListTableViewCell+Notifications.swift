/// Encapsulates logic that configures `ListTableViewCell` with `Notification` models.
///
extension ListTableViewCell {
    func configureWithNotification(_ notification: Notification) {
        indicatorColor = Style.unreadIndicatorColor
        showsIndicator = !notification.read
        configureImage(with: notification.iconURL)
        attributedTitleText = notification.renderSubject()
        snippetText = notification.renderSnippet()?.string ?? String()
    }

    /// Toggles an overlay view that presents an undo option for the user.
    /// Whether the view is displayed or not depends on the `text` parameter.
    /// Given an empty text, the method will try to dismiss the overlay text (if it exists).
    /// Otherwise, it will try to show the overlay view on top of the cell.
    /// - Parameters:
    ///     - text: The text describing the action that can be undone.
    ///     - onUndelete: The closure to be executed when the undo button is tapped.
    func configureUndeleteOverlay(with text: String?, onUndelete: @escaping () -> Void) {
        guard let someText = text, !someText.isEmpty else {
            dismissOverlay()
            return
        }

        let undoOverlayView = makeUndoOverlayView()
        undoOverlayView.textLabel.text = text
        undoOverlayView.actionButton.on(.touchUpInside) { _ in
            onUndelete()
        }

        showOverlay(with: undoOverlayView)
    }
}

// MARK: - Constants and Helpers

private extension ListTableViewCell {
    /// Creates a pre-styled overlay view based on `ListSimpleOverlayView`.
    /// This will be used to show options for the user to revert the action performed on the notification.
    func makeUndoOverlayView() -> ListSimpleOverlayView {
        let overlayView = ListSimpleOverlayView.loadFromNib()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = Style.noteUndoBackgroundColor

        // text label
        overlayView.textLabel.font = Style.noteUndoTextFont
        overlayView.textLabel.textColor = Style.noteUndoTextColor

        // action button
        overlayView.actionButton.titleLabel?.font = Style.noteUndoTextFont
        overlayView.actionButton.setTitleColor(Style.noteUndoTextColor, for: .normal)
        overlayView.actionButton.setTitle(Localization.undoButtonText, for: .normal)
        overlayView.actionButton.accessibilityHint = Localization.undoButtonHint

        return overlayView
    }

    typealias Style = WPStyleGuide.Notifications

    struct Localization {
        static let undoButtonText = NSLocalizedString("Undo", comment: "Revert an operation")
        static let undoButtonHint = NSLocalizedString("Reverts the action performed on this notification.",
                                                      comment: "Accessibility hint describing what happens if the undo button is tapped.")
    }
}
