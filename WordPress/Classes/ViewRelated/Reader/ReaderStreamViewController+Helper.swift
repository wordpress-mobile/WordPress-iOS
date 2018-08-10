import Foundation

extension ReaderStreamViewController {
    // Convenience type for Reader's headers
    typealias ReaderHeader = UIView & ReaderStreamHeader

    // A simple struct defining a title and message for use with a WPNoResultsView
    public struct NoResultsResponse {
        var title: String
        var message: String
    }

    /// Returns the ReaderStreamHeader appropriate for a particular ReaderTopic, including News Card, or nil if there is not one.
    /// The header is returned already configured
    ///
    /// - Parameter topic: A ReaderTopic
    /// - Parameter isLoggedIn: A boolean flag indicating if the user is logged in
    /// - Parameter delegate: The header delegate
    ///
    /// - Returns: A configured instance of UIView.
    ///
    public class func headerWithNewsCardForStream(_ topic: ReaderAbstractTopic, isLoggedIn: Bool, delegate: ReaderStreamHeaderDelegate) -> UIView? {

        let header = headerForStream(topic)
        let configuredHeader = configure(header, topic: topic, isLoggedIn: isLoggedIn, delegate: delegate)

        // Feature flag is not active
        if !FeatureFlag.newsCard.enabled {
            return configuredHeader
        }

        let containerIdentifier = Identifier(value: topic.title)

        return ReaderNewsCard.newsCard(containerIdentifier: containerIdentifier, header: header)
    }

    private class func configure(_ header: ReaderHeader?, topic: ReaderAbstractTopic, isLoggedIn: Bool, delegate: ReaderStreamHeaderDelegate) -> ReaderHeader? {
        header?.configureHeader(topic)
        header?.enableLoggedInFeatures(isLoggedIn)
        header?.delegate = delegate

        return header
    }

    private class func headerForStream(_ topic: ReaderAbstractTopic) -> ReaderHeader? {
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
