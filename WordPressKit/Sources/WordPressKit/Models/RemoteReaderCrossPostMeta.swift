import Foundation

open class RemoteReaderCrossPostMeta: NSObject {
    @objc open var postID: NSNumber = 0
    @objc open var siteID: NSNumber = 0
    @objc open var siteURL = ""
    @objc open var postURL = ""
    @objc open var commentURL = ""
}
