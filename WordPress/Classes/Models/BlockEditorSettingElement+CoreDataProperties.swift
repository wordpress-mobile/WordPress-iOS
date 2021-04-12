import Foundation
import CoreData

enum BlockEditorSettingElementTypes: String {
    case color
    case gradient
}

extension BlockEditorSettingElement {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlockEditorSettingElement> {
        return NSFetchRequest<BlockEditorSettingElement>(entityName: "BlockEditorSettingElement")
    }

    /// Stores the associated type that this object represents.
    /// Available types are defined in `BlockEditorSettingElementTypes`
    ///
    @NSManaged public var type: String

    /// Stores the value for the associated type. The associated field in the API response might differ based on the type.
    ///
    @NSManaged public var value: String

    /// Stores a unique key associated to the `value`.
    ///
    @NSManaged public var slug: String

    /// Stores a user friendly display name for the `slug`.
    ///
    @NSManaged public var name: String

    /// Stores a reference back to the parent `BlockEditorSettings`.
    ///
    @NSManaged public var settings: BlockEditorSettings
}

extension BlockEditorSettingElement: Identifiable {

}
