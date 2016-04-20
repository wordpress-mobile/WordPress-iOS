import Foundation
import CoreData

@objc public class SharingButton : NSManagedObject
{
    static let visible = "visible"
    static let hidden = "hidden"

    // Relations
    @NSManaged public var blog: Blog

    // Properties
    @NSManaged public var buttonID: String
    @NSManaged public var name: String
    @NSManaged public var shortname: String
    @NSManaged public var custom: Bool
    @NSManaged public var enabled: Bool
    @NSManaged public var visibility: String?
    @NSManaged public var order: NSNumber

    var visible: Bool {
        return visibility == SharingButton.visible
    }
}
