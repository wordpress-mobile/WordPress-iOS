extension Comment {

    // Optional in Core Data but are given default values.
    @NSManaged public var likeCount: Int16
    @NSManaged public var depth: Int16
    @NSManaged public var rawContent: String?

    // Not optional in Core Data, is given a default value.
    @NSManaged public var canModerate: Bool

    // Optional in Core Data (Relationships)
    @NSManaged public var blog: Blog?
    @NSManaged public var post: BasePost?

    // Optional in Core Data with no default values.
    // Cannot be optional in Swift.
    // Default values are set in CommentService.
    @NSManaged public var commentID: Int32
    @NSManaged public var postID: Int32
    @NSManaged public var parentID: Int32
    @NSManaged public var isLiked: Bool

    // Optional in Core Data with no default values.
    @NSManaged public var postTitle: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var link: String?
    @NSManaged public var status: String?
    @NSManaged public var type: String?
    @NSManaged public var author: String?
    @NSManaged public var author_email: String?
    @NSManaged public var author_url: String?
    @NSManaged public var authorAvatarURL: String?
    @NSManaged public var content: String?
    @NSManaged public var hierarchy: String?

    /*
     // Hierarchy is a string representation of a comments ancestors. Each ancestor's
     // is denoted by a ten character zero padded representation of its ID
     // (e.g. "0000000001"). Ancestors are separated by a period.
     // This allows hierarchical comments to be retrieved from core data by sorting
     // on hierarchy, and allows for new comments to be inserted without needing to
     // reorder the list.
     */
}
