/// Encapsulates logic that configures `ListTableViewCell` with `Comment` models.
///
extension ListTableViewCell {
    /// Configures the cell based on the provided `Comment` object.
    @objc func configure(with comment: Comment) {
        // indicator view
        indicatorColor = Style.pendingIndicatorColor
        showsIndicator = (comment.status == CommentStatusPending)

        // avatar image
        placeholderImage = Style.gravatarPlaceholderImage
        if let avatarURL = comment.avatarURLForDisplay() {
            configureImage(with: avatarURL)
        } else {
            configureImageWithGravatarEmail(comment.gravatarEmailForDisplay())
        }

        // title text
        let authorString = comment.authorForDisplay() ?? String()
        let postTitleString = comment.titleForDisplay() ?? Constants.noTitleString
        attributedTitleText = attributedTitle(for: authorString, postTitle: postTitleString)

        // snippet text
        snippetText = comment.contentPreviewForDisplay() ?? String()
    }

    // MARK: Private Helpers

    private func attributedTitle(for author: String, postTitle: String) -> NSAttributedString {
        let replacementMap = [
            "%1$@": NSAttributedString(string: author, attributes: ListStyle.titleBoldAttributes),
            "%2$@": NSAttributedString(string: postTitle, attributes: ListStyle.titleBoldAttributes)
        ]

        // Replace Author + Title
        let attributedTitle = NSMutableAttributedString(string: Constants.titleFormatString, attributes: ListStyle.titleRegularAttributes)

        for (key, attributedString) in replacementMap {
            let range = (attributedTitle.string as NSString).range(of: key)
            if range.location != NSNotFound {
                attributedTitle.replaceCharacters(in: range, with: attributedString)
            }
        }

        return attributedTitle
    }
}

// MARK: - Constants

private extension ListTableViewCell {
    typealias Style = WPStyleGuide.Comments
    typealias ListStyle = WPStyleGuide.List

    struct Constants {
        static let noTitleString = NSLocalizedString("(No Title)", comment: "Empty Post Title")
        static let titleFormatString = NSLocalizedString("%1$@ on %2$@", comment: "Label displaying the author and post title for a Comment. %1$@ is a placeholder for the author. %2$@ is a placeholder for the post title.")
    }
}
