import Foundation

extension ReaderStreamViewController {
    // Convenience type for Reader's headers
    typealias ReaderHeader = UIView & ReaderStreamHeader

    // A simple struct defining a title and message for use with a NoResultsViewController
    public struct NoResultsResponse {
        var title: String
        var message: String
    }

    /// Returns the ReaderStreamHeader appropriate for a particular ReaderTopic.
    /// The header is returned already configured
    ///
    /// - Parameter topic: A ReaderTopic
    /// - Parameter isLoggedIn: A boolean flag indicating if the user is logged in
    /// - Parameter delegate: The header delegate
    ///
    /// - Returns: A configured instance of UIView.
    ///
    func headerForStream(_ topic: ReaderAbstractTopic, isLoggedIn: Bool, container: UITableViewController) -> UIView? {

        let header = headerForStream(topic)
        configure(header, topic: topic, isLoggedIn: isLoggedIn, delegate: self)
        return header
    }

    func configure(_ header: ReaderHeader?, topic: ReaderAbstractTopic, isLoggedIn: Bool, delegate: ReaderStreamHeaderDelegate) {
        header?.configureHeader(topic)
        header?.enableLoggedInFeatures(isLoggedIn)
        header?.delegate = delegate
    }

    func headerForStream(_ topic: ReaderAbstractTopic) -> ReaderHeader? {

        if ReaderHelpers.isTopicTag(topic) && !isContentFiltered {
            return Bundle.main.loadNibNamed("ReaderTagStreamHeader", owner: nil, options: nil)?.first as? ReaderTagStreamHeader
        }

        if ReaderHelpers.isTopicList(topic) {
            return Bundle.main.loadNibNamed("ReaderListStreamHeader", owner: nil, options: nil)?.first as? ReaderListStreamHeader
        }

        if ReaderHelpers.isTopicSite(topic) {
            return Bundle.main.loadNibNamed("ReaderSiteStreamHeader", owner: nil, options: nil)?.first as? ReaderSiteStreamHeader
        }

        return nil
    }

    static let defaultResponse = NoResultsResponse(
        title: NSLocalizedString("No recent posts", comment: "A message title"),
        message: NSLocalizedString("No posts have been made recently", comment: "A default message shown whe the reader can find no post to display"))

    /// Returns a NoResultsResponse instance appropriate for the specified ReaderTopic
    ///
    /// - Parameter topic: A ReaderTopic.
    ///
    /// - Returns: An NoResultsResponse instance.
    ///
    public class func responseForNoResults(_ topic: ReaderAbstractTopic) -> NoResultsResponse {
        // if following
        if ReaderHelpers.topicIsFollowing(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("Welcome to the Reader", comment: "A message title"),
                message: NSLocalizedString("Recent posts from blogs and sites you follow will appear here.", comment: "A message explaining the Following topic in the reader")
            )
        }

        // if liked
        if ReaderHelpers.topicIsLiked(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("Nothing liked yet", comment: "A message title"),
                message: NSLocalizedString("Posts that you like will appear here.", comment: "A message explaining the Posts I Like feature in the reader")
            )
        }

        // if tag
        if ReaderHelpers.isTopicTag(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("No recent posts", comment: "A message title"),
                message: NSLocalizedString("No posts have been made recently with this tag.", comment: "Message shown whent the reader finds no posts for the chosen tag")
            )
        }

        // if site (blog)
        if ReaderHelpers.isTopicSite(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("No posts", comment: "A message title"),
                message: NSLocalizedString("This site has not posted anything yet. Try back later.", comment: "Message shown when the reader finds no posts for the chosen site")
            )
        }

        // if list
        if ReaderHelpers.isTopicList(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("No recent posts", comment: "A message title"),
                message: NSLocalizedString("The sites in this list have not posted anything recently.", comment: "Message shown when the reader finds no posts for the chosen list")
            )
        }

        // if search topic
        if ReaderHelpers.isTopicSearchTopic(topic) {
            let message = NSLocalizedString("No posts found matching %@ in your language.", comment: "Message shown when the reader finds no posts for the specified search phrase. The %@ is a placeholder for the search phrase.")
            return NoResultsResponse(
                title: NSLocalizedString("No posts found", comment: "A message title"),
                message: NSString(format: message as NSString, topic.title) as String
            )
        }

        // Default message
        return defaultResponse
    }
}


// MARK: - No Results for saved posts
extension ReaderStreamViewController {

    func configureNoResultsViewForSavedPosts() {

        let noResultsResponse = NoResultsResponse(title: NSLocalizedString("No Saved Posts",
                                                                           comment: "Message displayed in Reader Saved Posts view if a user hasn't yet saved any posts."),
                                                  message: NSLocalizedString("Tap [bookmark-outline] to save a post to your list.",
                                                                             comment: "A hint displayed in the Saved Posts section of the Reader. The '[bookmark-outline]' placeholder will be replaced by an icon at runtime – please leave that string intact."))

        var messageText = NSMutableAttributedString(string: noResultsResponse.message)

        // Get attributed string styled for No Results so it gets the correct font attributes added to it.
        // The font is used by the attributed string `replace(_:with:)` method below to correctly position the icon.
        let styledText = resultsStatusView.applyMessageStyleTo(attributedString: messageText)
        messageText = NSMutableAttributedString(attributedString: styledText)

        let icon = UIImage.gridicon(.bookmarkOutline, size: CGSize(width: 18, height: 18))
        messageText.replace("[bookmark-outline]", with: icon)

        resultsStatusView.configureForLocalData(title: noResultsResponse.title, attributedSubtitle: messageText, image: "wp-illustration-reader-empty")
    }
}


// MARK: - Undo cell for saved posts
extension ReaderStreamViewController {

    private enum UndoCell {
        static let nibName = "ReaderSavedPostUndoCell"
        static let reuseIdentifier = "ReaderUndoCellReuseIdentifier"
        static let height: CGFloat = 44
    }

    func setupUndoCell(_ tableView: UITableView) {
        let nib = UINib(nibName: UndoCell.nibName, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: UndoCell.reuseIdentifier)
    }

    func undoCell(_ tableView: UITableView) -> ReaderSavedPostUndoCell {
        return tableView.dequeueReusableCell(withIdentifier: UndoCell.reuseIdentifier) as! ReaderSavedPostUndoCell
    }

    func configureUndoCell(_ cell: ReaderSavedPostUndoCell, with post: ReaderPost) {
        cell.title.text = post.titleForDisplay()
        cell.delegate = self
    }
}


// MARK: - Tracks
extension ReaderStreamViewController {
    func trackSavedListAccessed() {
        WPAnalytics.track(.readerSavedListShown, properties: ["source": ReaderSaveForLaterOrigin.readerMenu.viewAllPostsValue])
    }
}
