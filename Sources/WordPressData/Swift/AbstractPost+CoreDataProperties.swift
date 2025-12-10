import Foundation
import CoreData

extension AbstractPost {

    // MARK: - Attributes

    @NSManaged public var dateModified: Date?
    @NSManaged public var order: Int64
    @NSManaged public var permalinkTemplateURL: String?
    @NSManaged public var revisions: [Any]?
    @NSManaged public var autoUploadAttemptsCount: NSNumber
    @NSManaged public var autosaveContent: String?
    @NSManaged public var autosaveExcerpt: String?
    @NSManaged public var autosaveTitle: String?
    @NSManaged public var autosaveModifiedDate: Date?
    @NSManaged public var autosaveIdentifier: NSNumber?
    @NSManaged public var foreignID: UUID?
    @NSManaged public var confirmedChangesTimestamp: Date?
    @NSManaged public var rawMetadata: Data?
    @NSManaged public var rawOtherTerms: Data?

    // MARK: - Relationships

    @NSManaged public var blog: Blog
    @NSManaged public var media: Set<Media>
    @NSManaged public var featuredImage: Media?
}

// MARK: - Generated Accessors for media

extension AbstractPost {
    @objc(addMediaObject:)
    @NSManaged public func addMediaObject(_ value: Media)

    @objc(removeMediaObject:)
    @NSManaged public func removeMediaObject(_ value: Media)

    @objc(addMedia:)
    @NSManaged public func addMedia(_ values: Set<Media>)

    @objc(removeMedia:)
    @NSManaged public func removeMedia(_ values: Set<Media>)
}
