import Foundation
import CoreData

@objc open class TimeZoneInfo: NSManagedObject {

    @NSManaged public var label: String
    @NSManaged public var group: String
    @NSManaged public var value: String

}
