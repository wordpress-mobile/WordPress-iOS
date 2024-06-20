import Foundation

@objcMembers public class RemoteReaderSite: NSObject {

    public var recordID: NSNumber!
    public var siteID: NSNumber!
    public var feedID: NSNumber!
    public var name: String!
    public var path: String! // URL
    public var icon: String! // Sites only
    public var isSubscribed: Bool = false

}
