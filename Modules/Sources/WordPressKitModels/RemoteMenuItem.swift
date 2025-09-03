import Foundation

@objcMembers public class RemoteMenuItem: NSObject {

    public var itemID: NSNumber?
    public var contentID: NSNumber?
    public var details: String?
    public var linkTarget: String?
    public var linkTitle: String?
    public var name: String?
    public var type: String?
    public var typeFamily: String?
    public var typeLabel: String?
    public var urlStr: String?
    public var classes: [String]?
    public var children: [RemoteMenuItem]?
    public weak var parentItem: RemoteMenuItem?

}
