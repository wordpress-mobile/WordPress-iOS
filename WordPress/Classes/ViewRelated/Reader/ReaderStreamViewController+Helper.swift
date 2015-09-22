import Foundation

extension ReaderStreamViewController
{

    struct ActionSheetButtonTitles
    {
        static let cancel = NSLocalizedString("Cancel", comment:"The title of a cancel button.")
        static let blockSite = NSLocalizedString("Block This Site", comment:"The title of a button that triggers blocking a site from the user's reader.")
        static let share = NSLocalizedString("Share", comment:"Verb. Title of a button. Pressing the lets the user share a post to others.")
        static let visit = NSLocalizedString("Visit Site", comment:"An option to visit the site to which a specific post belongs")
        static let unfollow = NSLocalizedString("Unfollow Site", comment:"Verb. An option to unfollow a site.")
        static let follow = NSLocalizedString("Follow Site", comment:"Verb. An option to follow a site.")
    }

    // A simple struct defining a title and message for use with a WPNoResultsView
    public struct NoResultsResponse
    {
        var title:String
        var message:String
    }


    /**
    Returns the ReaderStreamHeader appropriate for a particular ReaderTopic
    or nil if there is not one.  The caller is expected to configure the
    returned header.

    @param topic A ReaderTopic
    @param An unconfigured instance of a ReaderStreamHeader.
    */
    public class func headerForStream(topic: ReaderAbstractTopic) -> ReaderStreamHeader? {
        if ReaderHelpers.topicIsFollowing(topic) || ReaderHelpers.topicIsFreshlyPressed(topic) || ReaderHelpers.topicIsLiked(topic) {
            // no header for these special lists
            return nil
        }

        // if tag
        if ReaderHelpers.isTopicTag(topic) {
            return NSBundle.mainBundle().loadNibNamed("ReaderTagStreamHeader", owner: nil, options: nil).first as! ReaderTagStreamHeader
        }

        // if list
        if ReaderHelpers.isTopicList(topic) {
            return NSBundle.mainBundle().loadNibNamed("ReaderListStreamHeader", owner: nil, options: nil).first as! ReaderListStreamHeader
        }

        // if site
        if ReaderHelpers.isTopicSite(topic) {
            return NSBundle.mainBundle().loadNibNamed("ReaderSiteStreamHeader", owner: nil, options: nil).first as! ReaderSiteStreamHeader
        }

        // if anything else return nil
        return nil
    }

    /**
    Returns a NoResultsResponse instance appropriate for the specified ReaderTopic
    
    @param topic A ReaderTopic.
    @return An NoResultsResponse instance.
    */
    public class func responseForNoResults(topic: ReaderAbstractTopic) -> NoResultsResponse {
        // if following
        if ReaderHelpers.topicIsFollowing(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("Welcome to the reader", comment:"A message title"),
                message: NSLocalizedString("Recent posts from blogs and sites you follow will appear here.", comment:"A message explaining the Following topic in the reader")
            )
        }

        // if liked
        if ReaderHelpers.topicIsLiked(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("No likes yet", comment:"A message title"),
                message: NSLocalizedString("Posts that you like will appear here.", comment:"A message explaining the Posts I Like feature in the reader")
            )
        }

        // if tag
        if ReaderHelpers.isTopicTag(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("No recent posts", comment:"A message title"),
                message: NSLocalizedString("No posts have been made recently with this tag.", comment:"Message shown whent the reader finds no posts for the chosen tag")
            )
        }

        // if site (blog)
        if ReaderHelpers.isTopicSite(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("No posts", comment:"A message title"),
                message: NSLocalizedString("This site has not posted anything yet. Try back later.", comment:"Message shown when the reader finds no posts for the chosen site")
            )
        }

        // if list
        if ReaderHelpers.isTopicList(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("No recent posts", comment:"A message title"),
                message: NSLocalizedString("The sites in this list have not posted anything recently.", comment:"Message shown when the reader finds no posts for the chosen list")
            )
        }

        // Default message
        return NoResultsResponse(
            title: NSLocalizedString("No recent posts", comment:"A message title"),
            message: NSLocalizedString("No posts have been made recently", comment:"A default message shown whe the reader can find no post to display")
        )
    }

}
