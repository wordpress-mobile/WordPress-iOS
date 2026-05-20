import Foundation
import CoreData

@objc(PostCategory)
public class PostCategory: NSManagedObject {

    @objc override public class func entityName() -> String {
        return "Category"
    }

    @objc public static let uncategorized: NSNumber = 1
}
