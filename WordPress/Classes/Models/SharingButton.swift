import Foundation
import CoreData

@objc open class SharingButton: NSManagedObject {
    @objc static let visible = "visible"
    @objc static let hidden = "hidden"

    // Relations
    @NSManaged open var blog: Blog

    // Properties
    @NSManaged open var buttonID: String
    @NSManaged open var name: String
    @NSManaged open var shortname: String
    @NSManaged open var custom: Bool
    @NSManaged open var enabled: Bool
    @NSManaged open var visibility: String?
    @NSManaged open var order: NSNumber

    @objc var visible: Bool {
        return visibility == SharingButton.visible
    }
}
