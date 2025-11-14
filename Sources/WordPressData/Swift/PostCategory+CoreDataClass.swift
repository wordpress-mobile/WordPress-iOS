import Foundation
import CoreData

@objc(PostCategory)
public class PostCategory: NSManagedObject {

    @objc public override class func entityName() -> String {
        return "Category"
    }

    @objc public static var uncategorizedId: NSNumber {
        return 1
    }
}
