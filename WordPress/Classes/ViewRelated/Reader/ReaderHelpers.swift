import Foundation

public class ReaderHelpers {

    public class func shareController(title:String?, summary:String?, tags:String?, link:String?) -> UIActivityViewController {
        var activityItems = [AnyObject]()
        let postDictionary = NSMutableDictionary()

        if let str = title {
            postDictionary["title"] = str
        }
        if let str = summary {
            postDictionary["summary"] = str
        }
        if let str = tags {
            postDictionary["tags"] = str
        }

        activityItems.append(postDictionary)
        if let url = link {
            activityItems.append(url)
        }

        let activities = WPActivityDefaults.defaultActivities() as! [UIActivity]
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: activities)
        if let str = title {
            controller.setValue(str, forKey:"subject")
        }
        controller.completionHandler = { (activityType:String?, completed:Bool) in
            if completed {
                WPActivityDefaults.trackActivityType(activityType)
            }
        }

        return controller
    }


    // MARK: - Topic Helpers

    /**
    Check if the specified topic is a default topic

    @param topic A ReaderAbstractTopic
    @return True if the topic is a default topic
    */
    public class func isTopicDefault(topic:ReaderAbstractTopic) -> Bool {
        return topic.isKindOfClass(ReaderDefaultTopic)
    }

    /**
    Check if the specified topic is a list

    @param topic A ReaderAbstractTopic
    @return True if the topic is a list topic
    */
    public class func isTopicList(topic:ReaderAbstractTopic) -> Bool {
        return topic.isKindOfClass(ReaderListTopic)
    }

    /**
    Check if the specified topic is a site topic

    @param topic A ReaderAbstractTopic
    @return True if the topic is a site topic
    */
    public class func isTopicSite(topic:ReaderAbstractTopic) -> Bool {
        return topic.isKindOfClass(ReaderSiteTopic)
    }

    /**
    Check if the specified topic is a tag

    @param topic A ReaderAbstractTopic
    @return True if the topic is a tag topic
    */
    public class func isTopicTag(topic:ReaderAbstractTopic) -> Bool {
        return topic.isKindOfClass(ReaderTagTopic)
    }

    /**
    Check if the specified topic is for Freshly Pressed

    @param topic A ReaderAbstractTopic
    @return True if the topic is for Freshly Pressed
    */
    public class func topicIsFreshlyPressed(topic: ReaderAbstractTopic) -> Bool {
        let path = topic.path as NSString!
        return path.hasSuffix("/freshly-pressed")
    }

    /**
    Check if the specified topic is for Following

    @param topic A ReaderAbstractTopic
    @return True if the topic is for Following
    */
    public class func topicIsFollowing(topic: ReaderAbstractTopic) -> Bool {
        let path = topic.path as NSString!
        return path.hasSuffix("/read/following")
    }

    /**
    Check if the specified topic is for Posts I Like

    @param topic A ReaderAbstractTopic
    @return True if the topic is for Posts I Like
    */
    public class func topicIsLiked(topic: ReaderAbstractTopic) -> Bool {
        let path = topic.path as NSString!
        return path.hasSuffix("/read/liked")
    }

}
