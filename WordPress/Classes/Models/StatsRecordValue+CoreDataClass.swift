import Foundation
import CoreData

public class StatsRecordValue: NSManagedObject {
    public convenience init(parent: StatsRecord) {
        self.init(context: parent.managedObjectContext!)

        self.statsRecord = parent
        parent.addToValues(self)
    }

    func recordValueSingleValueValidation() throws {
        guard let parent = statsRecord else {
            throw StatsCoreDataValidationError.noParentStatsRecord
        }

        let fr: NSFetchRequest<StatsRecordValue> = StatsRecordValue.fetchRequest()
        fr.predicate = NSPredicate(format: "\(#keyPath(StatsRecordValue.statsRecord)) = %@", parent)

        try singleEntryTypeValidation(with: fr)
    }
}

protocol StatsRecordValueConvertible {
    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue]
    init?(statsRecordValues: [StatsRecordValue])

    static var recordType: StatsRecordType { get }
}

protocol TimeIntervalStatsRecordValueConvertible: StatsRecordValueConvertible {
    var recordPeriodType: StatsRecordPeriodType { get }
    var date: Date { get }
}
