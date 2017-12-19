import Foundation

@objc open class RemoteSharingButton: NSObject {
    @objc open var buttonID = ""
    @objc open var name = ""
    @objc open var shortname = ""
    @objc open var custom = false
    @objc open var enabled = false
    @objc open var visibility: String?
    @objc open var order: NSNumber = 0
}
