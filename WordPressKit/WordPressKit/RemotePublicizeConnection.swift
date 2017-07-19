import Foundation

@objc open class RemotePublicizeConnection: NSObject {
    open var connectionID: NSNumber = 0
    open var dateIssued = Date()
    open var dateExpires: Date? = nil
    open var externalID = ""
    open var externalName = ""
    open var externalDisplay = ""
    open var externalProfilePicture = ""
    open var externalProfileURL = ""
    open var externalFollowerCount: NSNumber = 0
    open var keyringConnectionID: NSNumber = 0
    open var keyringConnectionUserID: NSNumber = 0
    open var label = ""
    open var refreshURL = ""
    open var service = ""
    open var shared = false
    open var status = ""
    open var siteID: NSNumber = 0
    open var userID: NSNumber = 0
}
