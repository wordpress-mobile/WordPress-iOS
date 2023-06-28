import Foundation
import CoreData

/// `PublicizeInfo` encapsulates the information related to Jetpack Social auto-sharing.
///
/// WP.com sites will not have a `PublicizeInfo`, and currently doesn't have auto-sharing limitations.
/// Furthermore, sites eligible for unlimited sharing will still return a `PublicizeInfo` along with its sharing
/// limitations, but the numbers should be ignored (at least for now).
///
@objc public class PublicizeInfo: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PublicizeInfo> {
        return NSFetchRequest<PublicizeInfo>(entityName: "PublicizeInfo")
    }

}
