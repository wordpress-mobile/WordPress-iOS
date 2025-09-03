import Foundation

/// Encapsulates the autosave attributes of a post.
@objc
@objcMembers
public class RemotePostAutosave: NSObject {
    public var title: String?
    public var excerpt: String?
    public var content: String?
    public var modifiedDate: Date?
    public var identifier: NSNumber?
    public var authorID: String?
    public var postID: NSNumber?
    public var previewURL: String?
}
