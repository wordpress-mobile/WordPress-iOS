extension PrepublishingViewController {

    /// Determines whether the account and the post's blog is eligible to see auto-sharing options.
    var isEligibleForAutoSharing: Bool {
        let postObjectID = post.objectID
        let blogSupportsPublicize = coreDataStack.performQuery { context in
            let post = (try? context.existingObject(with: postObjectID)) as? Post
            return post?.blog.supportsPublicize() ?? false
        }

        return blogSupportsPublicize && FeatureFlag.jetpackSocial.enabled
    }

    func configureSocialCell(_ cell: UITableViewCell) {
        // TODO:
        // - Show the NoConnectionView if user has 0 connections.
        // - Properly create and configure the view models.
        let autoSharingView = UIView.embedSwiftUIView(PrepublishingAutoSharingView())
        cell.contentView.addSubview(autoSharingView)

        // Pin constraints to the cell's layoutMarginsGuide so that the content is properly aligned.
        NSLayoutConstraint.activate([
            autoSharingView.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
            autoSharingView.topAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.topAnchor),
            autoSharingView.bottomAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.bottomAnchor),
            autoSharingView.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor)
        ])
        cell.accessoryType = .disclosureIndicator
    }
}
