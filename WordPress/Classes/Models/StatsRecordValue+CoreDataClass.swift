import Foundation
import CoreData

public class StatsRecordValue: NSManagedObject {
    public convenience init(parent: StatsRecord) {
        self.init(context: parent.managedObjectContext!)

        self.statsRecord = parent
        parent.addToValues(self)
    }
}

protocol StatsRecordValueConvertible {
    func statsRecordValue(in context: NSManagedObjectContext) -> StatsRecordValue
    init(statsRecordValue: StatsRecordValue)

    static var recordType: StatsRecordType { get }
}
