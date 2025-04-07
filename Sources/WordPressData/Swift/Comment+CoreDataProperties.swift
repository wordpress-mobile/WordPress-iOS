extension Comment {
    @NSManaged public var commentID: Int32
    @NSManaged public var postID: Int32
    @NSManaged public var likeCount: Int16
    @NSManaged public var dateCreated: Date?
    @NSManaged public var isLiked: Bool
    @NSManaged public var canModerate: Bool
    @NSManaged public var content: String
    @NSManaged public var rawContent: String
    @NSManaged public var postTitle: String
    @NSManaged public var link: String
    @NSManaged public var status: String
    @NSManaged public var type: String
    @NSManaged public var authorID: Int32
    @NSManaged public var author: String
    @NSManaged public var author_email: String
    @NSManaged public var author_url: String
    @NSManaged public var authorAvatarURL: String
    @NSManaged public var author_ip: String

    // Relationships
    @NSManaged public var blog: Blog?
    @NSManaged public var post: BasePost?

    // Hierarchical properties
    @NSManaged public var parentID: Int32
    @NSManaged public var depth: Int16
    @NSManaged public var hierarchy: String
    @NSManaged public var replyID: Int32

    /// Determines if the comment should be displayed in the Reader comment thread.
    ///
    /// Note that this property is only updated and guaranteed to be correct within the comment thread.
    /// The value may be outdated when accessed from other places (e.g. My Sites, Notifications).
    @NSManaged public var visibleOnReader: Bool

    /*
     // Hierarchy is a string representation of a comments ancestors. Each ancestor's
     // is denoted by a ten character zero padded representation of its ID
     // (e.g. "0000000001"). Ancestors are separated by a period.
     // This allows hierarchical comments to be retrieved from core data by sorting
     // on hierarchy, and allows for new comments to be inserted without needing to
     // reorder the list.
     */
}
