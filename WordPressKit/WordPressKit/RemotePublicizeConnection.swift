import Foundation

@objc open class RemotePublicizeConnection: NSObject {
    @objc open var connectionID: NSNumber = 0
    @objc open var dateIssued = Date()
    @objc open var dateExpires: Date? = nil
    @objc open var externalID = ""
    @objc open var externalName = ""
    @objc open var externalDisplay = ""
    @objc open var externalProfilePicture = ""
    @objc open var externalProfileURL = ""
    @objc open var externalFollowerCount: NSNumber = 0
    @objc open var keyringConnectionID: NSNumber = 0
    @objc open var keyringConnectionUserID: NSNumber = 0
    @objc open var label = ""
    @objc open var refreshURL = ""
    @objc open var service = ""
    @objc open var shared = false
    @objc open var status = ""
    @objc open var siteID: NSNumber = 0
    @objc open var userID: NSNumber = 0
}
