import Foundation

/// ShareData is a state container for the share extension screens.
///
@objc
class ShareData: NSObject {

    /// Post's Title
    ///
    var title = ""

    /// Post's Content
    ///
    var contentBody = ""

    /// Post's Status
    ///
    var postStatus = "publish"

    /// Array of ID's and images
    ///
    var sharedImageDict = [String: URL]()
}
