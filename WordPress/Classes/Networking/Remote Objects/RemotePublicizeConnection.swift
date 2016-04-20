import Foundation

@objc public class RemotePublicizeConnection : NSObject
{
    public var connectionID: NSNumber = 0
    public var dateIssued = NSDate()
    public var dateExpires:NSDate? = nil
    public var externalID = ""
    public var externalName = ""
    public var externalDisplay = ""
    public var externalProfilePicture = ""
    public var externalProfileURL = ""
    public var externalFollowerCount: NSNumber = 0
    public var keyringConnectionID: NSNumber = 0
    public var keyringConnectionUserID: NSNumber = 0
    public var label = ""
    public var refreshURL = ""
    public var service = ""
    public var shared = false
    public var status = ""
    public var siteID: NSNumber = 0
    public var userID: NSNumber = 0
}
