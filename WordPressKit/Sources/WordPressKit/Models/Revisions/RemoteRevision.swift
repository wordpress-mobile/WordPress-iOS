import Foundation

/// Revision model
///
public struct RemoteRevision: Codable {
    /// Revision id
    public var id: Int

    /// Optional post content
    public var postContent: String?

    /// Optional post excerpt
    public var postExcerpt: String?

    /// Optional post title
    public var postTitle: String?

    /// Optional post date
    public var postDateGmt: String?

    /// Optional post modified date
    public var postModifiedGmt: String?

    /// Optional post author id
    public var postAuthorId: String?

    /// Optional revision diff
    public var diff: RemoteDiff?

    /// Mapping keys
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case postContent = "post_content"
        case postExcerpt = "post_excerpt"
        case postTitle = "post_title"
        case postDateGmt = "post_date_gmt"
        case postModifiedGmt = "post_modified_gmt"
        case postAuthorId = "post_author"
    }
}
