import Foundation

/// ShareData is a state container for the share extension screens.
///
@objc
class ShareData: NSObject {

    /// Selected Site's ID
    ///
    var selectedSiteID: Int?

    /// Selected Site's Name
    ///
    var selectedSiteName: String?

    /// Post's Title
    ///
    var title = ""

    /// Post's Content
    ///
    var contentBody = ""

    /// Post's status, set to publish by default
    ///
    var postStatus = "publish"

    /// Dictionary of URLs mapped to attachment ID's
    ///
    var sharedImageDict = [URL: String]()
}
