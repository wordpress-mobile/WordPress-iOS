import Foundation

/// The parameters required to create a post or a page.
public struct RemotePostCreateParameters: Equatable {
    public var type: String

    public var status: String
    public var date: Date?
    public var authorID: Int?
    public var title: String?
    public var content: String?
    public var password: String?
    public var excerpt: String?
    public var slug: String?
    public var featuredImageID: Int?

    // Pages
    public var parentPageID: Int?

    // Posts
    public var format: String?
    public var isSticky = false
    public var tags: [String] = []
    public var categoryIDs: [Int] = []
    public var metadata: Set<RemotePostMetadataItem> = []

    public init(type: String, status: String) {
        self.type = type
        self.status = status
    }
}

/// Represents a partial update to be applied to a post or a page.
public struct RemotePostUpdateParameters: Equatable {
    public var ifNotModifiedSince: Date?

    public var status: String?
    public var date: Date?
    public var authorID: Int?
    public var title: String??
    public var content: String??
    public var password: String??
    public var excerpt: String??
    public var slug: String??
    public var featuredImageID: Int??

    // Pages
    public var parentPageID: Int??

    // Posts
    public var format: String??
    public var isSticky: Bool?
    public var tags: [String]?
    public var categoryIDs: [Int]?
    public var metadata: Set<RemotePostMetadataItem>?

    public init() {}
}

public struct RemotePostMetadataItem: Hashable {
    public var id: String?
    public var key: String?
    public var value: String?

    public init(id: String?, key: String?, value: String?) {
        self.id = id
        self.key = key
        self.value = value
    }
}

// MARK: - Diff

extension RemotePostCreateParameters {
    /// Returns a diff required to update from the `previous` to the current
    /// version of the post.
    public func changes(from previous: RemotePostCreateParameters) -> RemotePostUpdateParameters {
        var changes = RemotePostUpdateParameters()
        if previous.status != status {
            changes.status = status
        }
        if previous.date != date {
            changes.date = date
        }
        if previous.authorID != authorID {
            changes.authorID = authorID
        }
        if (previous.title ?? "") != (title ?? "") {
            changes.title = (title ?? "")
        }
        if (previous.content ?? "") != (content ?? "") {
            changes.content = (content ?? "")
        }
        if (previous.password ?? "") != (password ?? "") {
            changes.password = password
        }
        if (previous.excerpt ?? "") != (excerpt ?? "") {
            changes.excerpt = (excerpt ?? "")
        }
        if (previous.slug ?? "") != (slug ?? "") {
            changes.slug = (slug ?? "")
        }
        if previous.featuredImageID != featuredImageID {
            changes.featuredImageID = featuredImageID
        }
        if previous.parentPageID != parentPageID {
            changes.parentPageID = parentPageID
        }
        if previous.format != format {
            changes.format = format
        }
        if previous.isSticky != isSticky {
            changes.isSticky = isSticky
        }
        if previous.tags != tags {
            changes.tags = tags
        }
        if Set(previous.categoryIDs) != Set(categoryIDs) {
            changes.categoryIDs = categoryIDs
        }
        if previous.metadata != metadata {
            changes.metadata = metadata
        }
        return changes
    }

    /// Applies the diff to the receiver.
    public mutating func apply(_ changes: RemotePostUpdateParameters) {
        if let status = changes.status {
            self.status = status
        }
        if let date = changes.date {
            self.date = date
        }
        if let authorID = changes.authorID {
            self.authorID = authorID
        }
        if let title = changes.title {
            self.title = title
        }
        if let content = changes.content {
            self.content = content
        }
        if let password = changes.password {
            self.password = password
        }
        if let excerpt = changes.excerpt {
            self.excerpt = excerpt
        }
        if let slug = changes.slug {
            self.slug = slug
        }
        if let featuredImageID = changes.featuredImageID {
            self.featuredImageID = featuredImageID
        }
        if let parentPageID = changes.parentPageID {
            self.parentPageID = parentPageID
        }
        if let format = changes.format {
            self.format = format
        }
        if let isSticky = changes.isSticky {
            self.isSticky = isSticky
        }
        if let tags = changes.tags {
            self.tags = tags
        }
        if let categoryIDs = changes.categoryIDs {
            self.categoryIDs = categoryIDs
        }
        if let metadata = changes.metadata {
            self.metadata = metadata
        }
    }
}

// MARK: - Encoding (WP.COM REST API)

private enum RemotePostWordPressComCodingKeys: String, CodingKey {
    case ifNotModifiedSince = "if_not_modified_since"
    case type
    case status
    case date
    case authorID = "author"
    case title
    case content
    case password
    case excerpt
    case slug
    case featuredImageID = "featured_image"
    case parentPageID = "parent"
    case terms
    case format
    case isSticky = "sticky"
    case categoryIDs = "categories_by_id"
    case metadata

    static let postTags = "post_tag"
}

struct RemotePostCreateParametersWordPressComEncoder: Encodable {
    let parameters: RemotePostCreateParameters

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RemotePostWordPressComCodingKeys.self)
        try container.encodeIfPresent(parameters.type, forKey: .type)
        try container.encodeIfPresent(parameters.status, forKey: .status)
        try container.encodeIfPresent(parameters.date, forKey: .date)
        try container.encodeIfPresent(parameters.authorID, forKey: .authorID)
        try container.encodeIfPresent(parameters.title, forKey: .title)
        try container.encodeIfPresent(parameters.content, forKey: .content)
        try container.encodeIfPresent(parameters.password, forKey: .password)
        try container.encodeIfPresent(parameters.excerpt, forKey: .excerpt)
        try container.encodeIfPresent(parameters.slug, forKey: .slug)
        try container.encodeIfPresent(parameters.featuredImageID, forKey: .featuredImageID)
        if !parameters.metadata.isEmpty {
            let metadata = parameters.metadata.map(RemotePostUpdateParametersWordPressComMetadata.init)
            try container.encode(metadata, forKey: .metadata)
        }

        // Pages
        try container.encodeIfPresent(parameters.parentPageID, forKey: .parentPageID)

        // Posts
        try container.encodeIfPresent(parameters.format, forKey: .format)
        if !parameters.tags.isEmpty {
            try container.encode([RemotePostWordPressComCodingKeys.postTags: parameters.tags], forKey: .terms)
        }
        if !parameters.categoryIDs.isEmpty {
            try container.encodeIfPresent(parameters.categoryIDs, forKey: .categoryIDs)
        }
        if parameters.isSticky {
            try container.encode(parameters.isSticky, forKey: .isSticky)
        }
    }

    // - warning: fixme
    static func encodeMetadata(_ metadata: Set<RemotePostMetadataItem>) -> [[String: Any]] {
        metadata.map { item in
            var operation = "update"
            if item.key == nil {
                if item.id != nil && item.value == nil {
                    operation = "delete"
                } else if item.id == nil && item.value != nil {
                    operation = "add"
                }
            }
            var dictionary: [String: Any] = [:]
            if let id = item.id { dictionary["id"] = id }
            if let value = item.value { dictionary["value"] = value }
            if let key = item.key { dictionary["key"] = key }
            dictionary["operation"] = operation
            return dictionary
        }
    }
}

struct RemotePostUpdateParametersWordPressComMetadata: Encodable {
    let id: String?
    let operation: String
    let key: String?
    let value: String?

    init(_ item: RemotePostMetadataItem) {
        if item.key == nil {
            if item.id != nil && item.value == nil {
                self.operation = "delete"
            } else if item.id == nil && item.value != nil {
                self.operation = "add"
            } else {
                self.operation = "update"
            }
        } else {
            self.operation = "update"
        }
        self.id = item.id
        self.key = item.key
        self.value = item.value
    }
}

struct RemotePostUpdateParametersWordPressComEncoder: Encodable {
    let parameters: RemotePostUpdateParameters

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RemotePostWordPressComCodingKeys.self)
        try container.encodeIfPresent(parameters.ifNotModifiedSince, forKey: .ifNotModifiedSince)

        try container.encodeIfPresent(parameters.status, forKey: .status)
        try container.encodeIfPresent(parameters.date, forKey: .date)
        try container.encodeIfPresent(parameters.authorID, forKey: .authorID)
        try container.encodeStringIfPresent(parameters.title, forKey: .title)
        try container.encodeStringIfPresent(parameters.content, forKey: .content)
        try container.encodeStringIfPresent(parameters.password, forKey: .password)
        try container.encodeStringIfPresent(parameters.excerpt, forKey: .excerpt)
        try container.encodeStringIfPresent(parameters.slug, forKey: .slug)
        if let value = parameters.featuredImageID {
            try container.encodeNullableID(value, forKey: .featuredImageID)
        }
        if let metadata = parameters.metadata, !metadata.isEmpty {
            let metadata = metadata.map(RemotePostUpdateParametersWordPressComMetadata.init)
            try container.encode(metadata, forKey: .metadata)
        }

        // Pages
        if let parentPageID = parameters.parentPageID {
            try container.encodeNullableID(parentPageID, forKey: .parentPageID)
        }

        // Posts
        try container.encodeIfPresent(parameters.format, forKey: .format)
        if let tags = parameters.tags {
            try container.encode([RemotePostWordPressComCodingKeys.postTags: tags], forKey: .terms)
        }
        try container.encodeIfPresent(parameters.categoryIDs, forKey: .categoryIDs)
        try container.encodeIfPresent(parameters.isSticky, forKey: .isSticky)
    }
}

// MARK: - Encoding (XML-RPC)

private enum RemotePostXMLRPCCodingKeys: String, CodingKey {
    case ifNotModifiedSince = "if_not_modified_since"
    case type = "post_type"
    case postStatus = "post_status"
    case date = "post_date"
    case authorID = "post_author"
    case title = "post_title"
    case content = "post_content"
    case password = "post_password"
    case excerpt = "post_excerpt"
    case slug = "post_name"
    case featuredImageID = "post_thumbnail"
    case parentPageID = "post_parent"
    case terms = "terms"
    case termNames = "terms_names"
    case format = "post_format"
    case isSticky = "sticky"
    case metadata = "custom_fields"

    static let taxonomyTag = "post_tag"
    static let taxonomyCategory = "category"
}

struct RemotePostCreateParametersXMLRPCEncoder: Encodable {
    let parameters: RemotePostCreateParameters

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RemotePostXMLRPCCodingKeys.self)
        try container.encode(parameters.type, forKey: .type)
        try container.encodeIfPresent(parameters.status, forKey: .postStatus)
        try container.encodeIfPresent(parameters.date, forKey: .date)
        try container.encodeIfPresent(parameters.authorID, forKey: .authorID)
        try container.encodeIfPresent(parameters.title, forKey: .title)
        try container.encodeIfPresent(parameters.content, forKey: .content)
        try container.encodeIfPresent(parameters.password, forKey: .password)
        try container.encodeIfPresent(parameters.excerpt, forKey: .excerpt)
        try container.encodeIfPresent(parameters.slug, forKey: .slug)
        try container.encodeIfPresent(parameters.featuredImageID, forKey: .featuredImageID)
        if !parameters.metadata.isEmpty {
            let metadata = parameters.metadata.map(RemotePostUpdateParametersXMLRPCMetadata.init)
            try container.encode(metadata, forKey: .metadata)
        }

        // Pages
        try container.encodeIfPresent(parameters.parentPageID, forKey: .parentPageID)

        // Posts
        try container.encodeIfPresent(parameters.format, forKey: .format)
        if !parameters.tags.isEmpty {
            try container.encode([RemotePostXMLRPCCodingKeys.taxonomyTag: parameters.tags], forKey: .termNames)
        }
        if !parameters.categoryIDs.isEmpty {
            try container.encode([RemotePostXMLRPCCodingKeys.taxonomyCategory: parameters.categoryIDs], forKey: .terms)
        }
        if parameters.isSticky {
            try container.encode(parameters.isSticky, forKey: .isSticky)
        }
    }
}

struct RemotePostUpdateParametersXMLRPCEncoder: Encodable {
    let parameters: RemotePostUpdateParameters

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RemotePostXMLRPCCodingKeys.self)
        try container.encodeIfPresent(parameters.ifNotModifiedSince, forKey: .ifNotModifiedSince)
        try container.encodeIfPresent(parameters.status, forKey: .postStatus)
        try container.encodeIfPresent(parameters.date, forKey: .date)
        try container.encodeIfPresent(parameters.authorID, forKey: .authorID)
        try container.encodeStringIfPresent(parameters.title, forKey: .title)
        try container.encodeStringIfPresent(parameters.content, forKey: .content)
        try container.encodeStringIfPresent(parameters.password, forKey: .password)
        try container.encodeStringIfPresent(parameters.excerpt, forKey: .excerpt)
        try container.encodeStringIfPresent(parameters.slug, forKey: .slug)
        if let value = parameters.featuredImageID {
            try container.encodeNullableID(value, forKey: .featuredImageID)
        }
        if let metadata = parameters.metadata, !metadata.isEmpty {
            let metadata = metadata.map(RemotePostUpdateParametersXMLRPCMetadata.init)
            try container.encode(metadata, forKey: .metadata)
        }

        // Pages
        if let parentPageID = parameters.parentPageID {
            try container.encodeNullableID(parentPageID, forKey: .parentPageID)
        }

        // Posts
        try container.encodeStringIfPresent(parameters.format, forKey: .format)
        if let tags = parameters.tags {
            try container.encode([RemotePostXMLRPCCodingKeys.taxonomyTag: tags], forKey: .termNames)
        }
        if let categoryIDs = parameters.categoryIDs {
            try container.encode([RemotePostXMLRPCCodingKeys.taxonomyCategory: categoryIDs], forKey: .terms)
        }
        try container.encodeIfPresent(parameters.isSticky, forKey: .isSticky)
    }
}

private struct RemotePostUpdateParametersXMLRPCMetadata: Encodable {
    let id: String?
    let key: String?
    let value: String?

    init(_ item: RemotePostMetadataItem) {
        self.id = item.id
        self.key = item.key
        self.value = item.value
    }
}

private extension KeyedEncodingContainer {
    mutating func encodeStringIfPresent(_ value: String??, forKey key: Key) throws {
        guard let value else { return }
        try encode(value ?? "", forKey: key)
    }

    /// - note: Some IDs are passed as integers, but, to reset them, you need to pass
    /// an empty string (passing `nil` does not work)
    mutating func encodeNullableID(_ value: Int?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        } else {
            try encode("", forKey: key)
        }
    }
}
