import Foundation
import CoreData

extension BlockEditorSettings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlockEditorSettings> {
        return NSFetchRequest<BlockEditorSettings>(entityName: "BlockEditorSettings")
    }

    /// Stores a n MD5 checksum representing the stored data. Used for a comparison to decide if the data has changed.
    ///
    @NSManaged public var checksum: String

    /// Stores a Bool indicating if the theme supports Full Site Editing (FSE) or not. `true` means the theme is an FSE theme.
    /// Default is `false`
    ///
    @NSManaged public var isFSETheme: Bool

    /// Stores a date indicating the last time stamp that the settings were modified. 
    ///
    @NSManaged public var lastUpdated: Date

    /// Stores the raw JSON string that comes from the Global Styles Setting Request. 
    ///
    @NSManaged public var rawStyles: String?

    /// Stores the raw JSON string that comes from the Global Styles Setting Request.
    ///
    @NSManaged public var rawFeatures: String?

    /// Stores a set of attributes describing values that are represented with arrays in the API request.
    /// Available types are defined in `BlockEditorSettingElementTypes`
    ///
    @NSManaged public var elements: Set<BlockEditorSettingElement>?

    /// Stores a reference back to the parent blog. 
    ///
    @NSManaged public var blog: Blog
}

// MARK: Generated accessors for elements
extension BlockEditorSettings {

    @objc(addElementsObject:)
    @NSManaged public func addToElements(_ value: BlockEditorSettingElement)

    @objc(removeElementsObject:)
    @NSManaged public func removeFromElements(_ value: BlockEditorSettingElement)

    @objc(addElements:)
    @NSManaged public func addToElements(_ values: Set<BlockEditorSettingElement>)

    @objc(removeElements:)
    @NSManaged public func removeFromElements(_ values: Set<BlockEditorSettingElement>)
}

extension BlockEditorSettings: Identifiable {

}
