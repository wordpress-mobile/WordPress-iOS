import Foundation

public class ReaderHelpers {

    public class func shareController(title:String?, summary:String?, tags:String?, link:String?) -> UIActivityViewController {
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
