import Foundation

class ReaderHelpers {

    public class func shareControllerForPost(post:ReaderPost) -> UIActivityViewController {
        var title = post.postTitle
        var summary = post.summary
        var tags = post.tags
        var link = NSURL(string:post.permaLink)

        var activityItems = [AnyObject]()
        var postDictionary = NSMutableDictionary()

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

        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: WPActivityDefaults.defaultActivities())
        if let str = title {
            controller.setValue(str, forKey:"subject")
        }
        controller.completionHandler = { (activityType:String!, completed:Bool) in
            if completed {
                WPActivityDefaults.trackActivityType(activityType)
            }
        }

        return controller
    }

}
