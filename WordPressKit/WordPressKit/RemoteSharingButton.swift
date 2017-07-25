import Foundation

@objc open class RemoteSharingButton: NSObject {
    open var buttonID = ""
    open var name = ""
    open var shortname = ""
    open var custom = false
    open var enabled = false
    open var visibility: String?
    open var order: NSNumber = 0
}
