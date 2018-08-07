import Foundation

extension ReaderStreamViewController {

    // A simple struct defining a title and message for use with a WPNoResultsView
    public struct NoResultsResponse {
        var title: String
        var message: String
    }

    public class func headerWithNewsCardForStream(_ topic: ReaderAbstractTopic, isLoggedIn: Bool, delegate: ReaderStreamViewController) -> UIView? {
        let newsManager = DefaultNewsManager(service: LocalNewsService(fileName: "News"))
        let newsCard = NewsCard(manager: newsManager)
        let news = News(manager: newsManager, ui: newsCard)

        let header = headerForStream(topic)

        guard let cardUI = news.card?.view else {
            // No news
            let headerAsStreamHeader = header as? ReaderStreamHeader
            headerAsStreamHeader?.configureHeader(topic)
            headerAsStreamHeader?.enableLoggedInFeatures(isLoggedIn)
            headerAsStreamHeader?.delegate = delegate

            return headerAsStreamHeader as? UIView
        }

        let headerAsStreamHeader = header as? ReaderStreamHeader
        headerAsStreamHeader?.configureHeader(topic)
        headerAsStreamHeader?.enableLoggedInFeatures(isLoggedIn)
        headerAsStreamHeader?.delegate = delegate

        guard let sectionHeader = header else {
            return cardUI
        }


        let stackView = UIStackView(arrangedSubviews: [cardUI, sectionHeader])
        stackView.axis = .vertical
        return stackView

    }


    /// Returns the ReaderStreamHeader appropriate for a particular ReaderTopic or nil if there is not one.
    /// The caller is expected to configure the returned header.
    ///
    /// - Parameter topic: A ReaderTopic
    ///
    /// - Returns: An unconfigured instance of a ReaderStreamHeader.
    ///
    public class func headerForStream(_ topic: ReaderAbstractTopic) -> UIView? {
        if ReaderHelpers.topicIsFreshlyPressed(topic) || ReaderHelpers.topicIsLiked(topic) {
            // no header for these special lists
            return nil
        }

        if ReaderHelpers.topicIsFollowing(topic) {
            return Bundle.main.loadNibNamed("ReaderFollowedSitesStreamHeader", owner: nil, options: nil)!.first as! ReaderFollowedSitesStreamHeader
        }

        // if tag
        if ReaderHelpers.isTopicTag(topic) {
            return Bundle.main.loadNibNamed("ReaderTagStreamHeader", owner: nil, options: nil)!.first as! ReaderTagStreamHeader
        }

        // if list
        if ReaderHelpers.isTopicList(topic) {
            return Bundle.main.loadNibNamed("ReaderListStreamHeader", owner: nil, options: nil)!.first as! ReaderListStreamHeader
        }

        // if site
        if ReaderHelpers.isTopicSite(topic) {
            return Bundle.main.loadNibNamed("ReaderSiteStreamHeader", owner: nil, options: nil)!.first as! ReaderSiteStreamHeader
        }

        // if anything else return nil
        return nil
    }

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
                title: NSLocalizedString("No likes yet", comment: "A message title"),
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
        return NoResultsResponse(
            title: NSLocalizedString("No recent posts", comment: "A message title"),
            message: NSLocalizedString("No posts have been made recently", comment: "A default message shown whe the reader can find no post to display")
        )
    }

}
