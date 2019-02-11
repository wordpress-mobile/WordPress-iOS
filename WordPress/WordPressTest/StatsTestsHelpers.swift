@testable import WordPress

@discardableResult func createStatsRecord(in context: NSManagedObjectContext, type: StatsRecordType, date: Date) -> StatsRecord {
    let newRecord = StatsRecord(context: context)
    newRecord.type = type.rawValue
    newRecord.date = date as NSDate

    return newRecord
}
