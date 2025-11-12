import Foundation
import CoreData

@objc(MenuLocation)
public class MenuLocation: NSManagedObject {
}

// MARK: - Core Data Properties

public extension MenuLocation {
    @NSManaged var defaultState: String?
    @NSManaged var details: String?
    @NSManaged var name: String?

    @NSManaged var blog: Blog?
    @NSManaged var menu: Menu?
}
