import Foundation

extension ReaderStreamViewController
{

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
    public class func headerForStream(topic: ReaderTopic) -> ReaderStreamHeader? {
        if topicIsFollowing(topic) || topicIsFreshlyPressed(topic) || topicIsLiked(topic) {
            // no header for these special lists
            return nil
        }

        // if tag
        if topic.isTag() {
            return NSBundle.mainBundle().loadNibNamed("ReaderTagStreamHeader", owner: nil, options: nil).first as! ReaderTagStreamHeader
        }

        // if list
        if topic.isList() {
            return NSBundle.mainBundle().loadNibNamed("ReaderListStreamHeader", owner: nil, options: nil).first as! ReaderListStreamHeader
        }

        // if site
        if topic.isSite() {
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
    public class func responseForNoResults(topic: ReaderTopic) -> NoResultsResponse {
        let path = topic.path as NSString!

        // if following
        if topicIsFollowing(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("Welcome to the reader", comment:"A message title"),
                message: NSLocalizedString("Recent posts from blogs and sites you follow will appear here.", comment:"A message explaining the Following topic in the reader")
            )
        }

        // if liked
        if topicIsLiked(topic) {
            return NoResultsResponse(
                title: NSLocalizedString("No likes yet", comment:"A message title"),
                message: NSLocalizedString("Posts that you like will appear here.", comment:"A message explaining the Posts I Like feature in the reader")
            )
        }

        // if tag
        if topic.isTag() {
            return NoResultsResponse(
                title: NSLocalizedString("No recent posts", comment:"A message title"),
                message: NSLocalizedString("No posts have been made recently with this tag.", comment:"Message shown whent the reader finds no posts for the chosen tag")
            )
        }

        // if site (blog)
        if topic.isSite() {
            return NoResultsResponse(
                title: NSLocalizedString("No posts", comment:"A message title"),
                message: NSLocalizedString("This site has not posted anything yet. Try back later.", comment:"Message shown when the reader finds no posts for the chosen site")
            )
        }

// TODO: Wire up when we can distinguish between wpcom and external sites
//        // if set (feed)
//        if topic.isSite() {
//            return NoResultsResponse(
//                title: NSLocalizedString("No recent posts", comment:"A message title"),
//                message: NSLocalizedString("This site has not posted anything recently", comment:"Message shown wehen the reader finds no posts for the chosen external site")
//            )
//        }

        // if list
        if topic.isList() {
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

    /**
    Check if the specified topic is for Freshly Pressed

    @param topic A ReaderTopic
    @return True if the topic is for Freshly Pressed
    */
    public class func topicIsFreshlyPressed(topic: ReaderTopic) -> Bool {
        let path = topic.path as NSString!
        return path.hasSuffix("/freshly-pressed/")
    }

    /**
    Check if the specified topic is for Following

    @param topic A ReaderTopic
    @return True if the topic is for Following
    */
    public class func topicIsFollowing(topic: ReaderTopic) -> Bool {
        let path = topic.path as NSString!
        return path.hasSuffix("/read/following/")
    }

    /**
    Check if the specified topic is for Posts I Like

    @param topic A ReaderTopic
    @return True if the topic is for Posts I Like
    */
    public class func topicIsLiked(topic: ReaderTopic) -> Bool {
        let path = topic.path as NSString!
        return path.hasSuffix("/read/liked/")
    }

}
