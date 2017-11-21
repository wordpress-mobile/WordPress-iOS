import Foundation
import CoreData

@objc open class TimezoneInfo: NSManagedObject {

    @NSManaged public var label: String
    @NSManaged public var continent: String
    @NSManaged public var value: String

}
