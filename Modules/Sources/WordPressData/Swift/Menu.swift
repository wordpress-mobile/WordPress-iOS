import Foundation
import CoreData

@objc(Menu)
public class Menu: NSManagedObject {
    @objc public static let defaultID: Int = -1

    @objc(newMenu:)
    public static func newMenu(in managedObjectContext: NSManagedObjectContext) -> Menu {
        NSEntityDescription.insertNewObject(forEntityName: Menu.entityName(), into: managedObjectContext) as! Menu
    }

    @objc(defaultMenuForBlog:)
    public static func defaultMenu(for blog: Blog) -> Menu? {
        for menu in blog.menus ?? NSOrderedSet() {
            if let menu = menu as? Menu, menu.isDefaultMenu {
                return menu
            }
        }
        return nil
    }

    @objc(newDefaultMenu:)
    public static func newDefaultMenu(in managedObjectContext: NSManagedObjectContext) -> Menu {
        let defaultMenu = newMenu(in: managedObjectContext)
        defaultMenu.menuID = NSNumber(value: defaultID)
        defaultMenu.name = defaultMenuName()
        return defaultMenu
    }

    @objc(defaultMenuName)
    public static func defaultMenuName() -> String {
        return NSLocalizedString(
            "Default Menu",
            comment: "Menu name for the default menu that is automatically generated."
        )
    }

    @objc public var isDefaultMenu: Bool {
        return menuID?.intValue == Menu.defaultID
    }
}
