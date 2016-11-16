import Foundation

extension ReaderStreamViewController
{

    // A simple struct defining a title and message for use with a WPNoResultsView
    public struct NoResultsResponse
    {
        var title:String
        var message:String
    }


    /// Returns the ReaderStreamHeader appropriate for a particular ReaderTopic or nil if there is not one.
    /// The caller is expected to configure the returned header.
    ///
    /// - Parameter topic: A ReaderTopic
    ///
    /// - Returns: An unconfigured instance of a ReaderStreamHeader.
    ///
    public class func headerForStream(topic: ReaderAbstractTopic) -> ReaderStreamHeader? {
        if topic.isFreshlyPressed || topic.isLiked {
            // no header for these special lists
            return nil
        }

        if topic.isFollowing {
            return NSBundle.mainBundle().loadNibNamed("ReaderFollowedSitesStreamHeader", owner: nil, options: nil)!.first as! ReaderFollowedSitesStreamHeader
        }

        // if tag
        if topic.isTag {
            return NSBundle.mainBundle().loadNibNamed("ReaderTagStreamHeader", owner: nil, options: nil)!.first as! ReaderTagStreamHeader
        }

        // if list
        if topic.isList {
            return NSBundle.mainBundle().loadNibNamed("ReaderListStreamHeader", owner: nil, options: nil)!.first as! ReaderListStreamHeader
        }

        // if site
        if topic.isSite {
            return NSBundle.mainBundle().loadNibNamed("ReaderSiteStreamHeader", owner: nil, options: nil)!.first as! ReaderSiteStreamHeader
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
    public class func responseForNoResults(topic: ReaderAbstractTopic) -> NoResultsResponse {
        // if following
        if topic.isFollowing {
            return NoResultsResponse(
                title: NSLocalizedString("Welcome to the Reader", comment:"A message title"),
                message: NSLocalizedString("Recent posts from blogs and sites you follow will appear here.", comment:"A message explaining the Following topic in the reader")
            )
        }

        // if liked
        if topic.isLiked {
            return NoResultsResponse(
                title: NSLocalizedString("No likes yet", comment:"A message title"),
                message: NSLocalizedString("Posts that you like will appear here.", comment:"A message explaining the Posts I Like feature in the reader")
            )
        }

        // if tag
        if topic.isTag {
            return NoResultsResponse(
                title: NSLocalizedString("No recent posts", comment:"A message title"),
                message: NSLocalizedString("No posts have been made recently with this tag.", comment:"Message shown whent the reader finds no posts for the chosen tag")
            )
        }

        // if site (blog)
        if topic.isSite {
            return NoResultsResponse(
                title: NSLocalizedString("No posts", comment:"A message title"),
                message: NSLocalizedString("This site has not posted anything yet. Try back later.", comment:"Message shown when the reader finds no posts for the chosen site")
            )
        }

        // if list
        if topic.isList {
            return NoResultsResponse(
                title: NSLocalizedString("No recent posts", comment:"A message title"),
                message: NSLocalizedString("The sites in this list have not posted anything recently.", comment:"Message shown when the reader finds no posts for the chosen list")
            )
        }

        // if search topic
        if topic.isSearch {
            let message = NSLocalizedString("No posts found matching %@ in your language.", comment:"Message shown when the reader finds no posts for the specified search phrase. The %@ is a placeholder for the search phrase.")
            return NoResultsResponse(
                title: NSLocalizedString("No posts found", comment:"A message title"),
                message: NSString(format: message, topic.title) as String
            )
        }

        // Default message
        return NoResultsResponse(
            title: NSLocalizedString("No recent posts", comment:"A message title"),
            message: NSLocalizedString("No posts have been made recently", comment:"A default message shown whe the reader can find no post to display")
        )
    }

}
