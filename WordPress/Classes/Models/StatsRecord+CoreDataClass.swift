import Foundation
import CoreData

// Architecture of this deserves some explanation.
// Stats feature has a bunch of data points that are sorta-kinda similar to each other
// (most things have a name! most of them have some sort of loosely defined "value"! many have URLs!
// some have images!), but are unfortunately distinct enough for a unified "StatsObject" to not make too much sense
// (or at least, not without packing the umbrella type with a bunch of loosely related property that
// only some of the types will actually provide, and at that point — those should be separate types anyway.)
//
// Instead, `StatsRecord` acts as sort of marker, prividing information that we have a datapoint of
// specific `StatsRecordType`, for a specific `Date` and belonging to a specific `blog` —
// and the storage of actual, useful data is delegated to a specific subentities — like `LastPostStatsRecordValue` or
// `AllTimeStatsRecordValue`. Those subentities are related to a specific `StatsRecord` via a one-to-many `values` relationship
// Some `RecordTypes` (specifically most Insights) support only single children value — other types,
/// like stats for a blog (or a list of top categories) will support mutliple.
//
// All the specific subentities types have an abstract `StatsRecordValue` parent entity, which provides
// the relationship back to the `StatsRecordType` and some helper functions to aid in creating/fetching those.
//
// This will result in a slightly more verbose call-side code (the callers will need to know
// what kind of `StatsRecordValue` they're expecting and cast appriopriately), in return for
// benefit of having a stricter typing of those results and avoiding an umbrella type with 60 different properties.
// This should help with ease of maintenance down the line, and hopefully will help avoid some bugs due to
// shoving all kinds of stuff into some sort of `StatsObject`.

public enum StatsRecordType: Int16 {
    case allTimeStatsInsight
    case followers
    case lastPostInsight
    case publicizeConnection
    case streakInsight
    case tagsAndCategories
    case commentInsight
    case annualAndMostPopularTimes
    case today

    case blogVisitsSummary
    case clicks
    case countryViews
    case postViews
    case publishedPosts
    case referrers
    case searchTerms
    case topViewedPost
    case videos
    case topViewedAuthor
    case fileDownloads

    fileprivate var requiresDate: Bool {
        // For some kinds of data, we'll only support storing one dataPoint (it doesn't make a whole
        // lot of sense to hold on to Insights from the past...).
        // This lets us disambiguate between which is which.
        switch self {
        case  .allTimeStatsInsight,
              .followers,
              .lastPostInsight,
              .publicizeConnection,
              .streakInsight,
              .tagsAndCategories,
              .today,
              .commentInsight,
              .annualAndMostPopularTimes:

            return false
        case  .blogVisitsSummary,
              .clicks,
              .countryViews,
              .publishedPosts,
              .referrers,
              .searchTerms,
              .topViewedAuthor,
              .topViewedPost,
              .videos,
              .postViews,
              .fileDownloads:

            return true
        }
    }
}

public enum StatsRecordPeriodType: Int16 {
    case day
    case week
    case month
    case year
    case notApplicable // this doesn't apply to Insights.

    init(remoteStatus: StatsPeriodUnit) {
        switch remoteStatus {
        case .day:
            self = .day
        case .week:
            self = .week
        case .month:
            self = .month
        case .year:
            self = .year
        }
    }

    var statsPeriodUnitValue: StatsPeriodUnit {
        switch self {
        case .day:
            return .day
        case .week:
            return .week
        case .month:
            return .month
        case .year:
            return .year
        case .notApplicable:
            fatalError("Calling statsPeriodUnitValue on `StatsRecordPeriodType.notApplicable` is an error.")
        }
    }
}


public class StatsRecord: NSManagedObject {

    class func fetchRequest(for kind: StatsRecordType, on day: Date = Date(), periodType: StatsRecordPeriodType = .notApplicable) -> NSFetchRequest<StatsRecord> {
        let fr: NSFetchRequest<StatsRecord> = self.fetchRequest()

        let calendar = Calendar.autoupdatingCurrent

        let typePredicate = NSPredicate(format: "\(#keyPath(StatsRecord.type)) = %i", kind.rawValue)

        guard kind.requiresDate else {
            fr.predicate = typePredicate
            return fr
        }

        let datePredicate = NSPredicate(format: "\(#keyPath(StatsRecord.date)) == %@", calendar.startOfDay(for: day) as NSDate)
        let periodTypePredicate = NSPredicate(format: "\(#keyPath(StatsRecord.period)) == %i", periodType.rawValue)

        fr.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            typePredicate,
            NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate,
                                                               periodTypePredicate])])

        return fr
    }

    public class func insightFetchRequest(for blog: Blog, type: StatsRecordType) -> NSFetchRequest<StatsRecord> {
        precondition(type.requiresDate == false, "This can only by used with StatsRecords that don't require date")

        let fr: NSFetchRequest<StatsRecord> = self.fetchRequest()

        let blogPredicate = NSPredicate(format: "\(#keyPath(StatsRecord.blog)) = %@", blog)
        let typePredicate = NSPredicate(format: "\(#keyPath(StatsRecord.type)) = %i", type.rawValue)

        let compoundPredicate =  NSCompoundPredicate(andPredicateWithSubpredicates: [
            blogPredicate,
            typePredicate
        ])

        fr.predicate = compoundPredicate

        return fr
    }

    public class func insight(for blog: Blog, type: StatsRecordType) -> StatsRecord? {
        guard let moc = blog.managedObjectContext else {
            DDLogDebug("`Blog` with no `NSManagedObjectContext` attatched was passed to `StatsRecord.insight(blog:_type:_) -> StatsRecord`. This is probably an error.")
            return nil
        }

        let fetchRequest = self.insightFetchRequest(for: blog, type: type)
        let fetchResults = try? moc.fetch(fetchRequest)

        return fetchResults?.first
    }

    public class func timeIntervalFetchRequest(for blog: Blog, type: StatsRecordType, period: StatsRecordPeriodType, date: Date) -> NSFetchRequest<StatsRecord> {
        let blogPredicate = NSPredicate(format: "\(#keyPath(StatsRecord.blog)) =  %@", blog)

        let fetchRequest = self.fetchRequest(for: type, on: date, periodType: period)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [fetchRequest.predicate!, blogPredicate])

        return fetchRequest
    }

    public class func timeIntervalData(for blog: Blog, type: StatsRecordType, period: StatsRecordPeriodType, date: Date) -> StatsRecord? {
        guard let moc = blog.managedObjectContext else {
            DDLogDebug("`Blog` with no `NSManagedObjectContext` attatched was passed to `StatsRecord.timeIntervalData(blog:_type:_) -> StatsRecord`. This is probably an error.")
            return nil
        }

        let fetchRequest = self.timeIntervalFetchRequest(for: blog, type: type, period: period, date: date)
        let fetchResults = try? moc.fetch(fetchRequest)

        return fetchResults?.first
    }

    public override func validateForInsert() throws {
        try super.validateForInsert()

        guard let unwrappedBlog = blog else {
            throw StatsCoreDataValidationError.noBlog
        }

        guard let recordType = StatsRecordType(rawValue: type) else {
            throw StatsCoreDataValidationError.incorrectRecordType
        }

        if recordType.requiresDate {
            guard date != nil else {
                throw StatsCoreDataValidationError.noDate
            }
            guard period != StatsRecordPeriodType.notApplicable.rawValue else {
                throw StatsCoreDataValidationError.invalidPeriod
            }
        } else {
            let insightFetchRequest = Swift.type(of: self).insightFetchRequest(for: unwrappedBlog, type: recordType)
            try singleEntryTypeValidation(with: insightFetchRequest)

            guard period == StatsRecordPeriodType.notApplicable.rawValue else {
                throw StatsCoreDataValidationError.invalidPeriod
            }
        }
    }

    var recordValues: [StatsRecordValue] {
        return values?.array as? [StatsRecordValue] ?? []
    }
}

public enum StatsCoreDataValidationError: Error {

    case incorrectRecordType
    case noManagedObjectContext
    case noDate
    case invalidPeriod
    case invalidEnumValue
    case noBlog
    case noParentStatsRecord

    /// Thrown when trying to insert a second instance of a type that only supports
    /// a single entry being present in the Core Data store.
    case singleEntryTypeViolation
}

extension NSManagedObject {
    public func singleEntryTypeValidation<T>(with fetchRequest: NSFetchRequest<T>) throws {
        guard let moc = managedObjectContext else {
            throw StatsCoreDataValidationError.noManagedObjectContext
        }

        let existingObjectsCount = try moc.count(for: fetchRequest)

        guard existingObjectsCount == 1 else {
            throw StatsCoreDataValidationError.singleEntryTypeViolation
        }
    }
}

extension StatsRecord {
    static func record<InsightType: StatsInsightData & StatsRecordValueConvertible>(from remoteInsight: InsightType, for blog: Blog) -> StatsRecord {
        guard let managedObjectContext = blog.managedObjectContext else {
            preconditionFailure("Blog` with no `NSManagedObjectContext` attatched was passed to `StatsRecord.record(from:_for:_)`. This is an error.")
        }

        let recordType = InsightType.recordType
        let parentRecord: StatsRecord

        if let record = self.insight(for: blog, type: recordType) {
            parentRecord = record
        } else {
            parentRecord = StatsRecord(context: managedObjectContext)
            parentRecord.blog = blog
            parentRecord.period = StatsRecordPeriodType.notApplicable.rawValue
            parentRecord.type = recordType.rawValue
        }

        let newValues = remoteInsight.statsRecordValues(in: managedObjectContext)

        let valuesForDeletion: [NSManagedObject]

        if recordType == .followers {

            let followerStatsType: Int16

            if InsightType.self == StatsDotComFollowersInsight.self {
                followerStatsType = FollowersStatsType.dotCom.rawValue
            }
            else {
                followerStatsType = FollowersStatsType.email.rawValue
            }

            var records: [NSManagedObject?] = (parentRecord.values?.array ?? [])
                .compactMap { return $0 as? FollowersStatsRecordValue }
                .filter { return $0.type == followerStatsType }

            let countRecord = parentRecord.values?.first { ($0 as? FollowersCountStatsRecordValue)?.type == followerStatsType } as? NSManagedObject
            records.append(countRecord)

            valuesForDeletion = records.compactMap { $0 }
        }
        else {
            valuesForDeletion = (parentRecord.values?.array as? [NSManagedObject]) ?? []
        }

        valuesForDeletion.forEach {
            managedObjectContext.deleteObject($0 as! StatsRecordValue)
        }


        parentRecord.addToValues(NSOrderedSet(array: newValues))

        parentRecord.fetchedDate = Date() as NSDate

        return parentRecord
    }
}

extension StatsRecord {
    static func record<TimeIntervalType: StatsTimeIntervalData & TimeIntervalStatsRecordValueConvertible>(from timeIntervalData: TimeIntervalType, for blog: Blog) -> StatsRecord {
        guard let managedObjectContext = blog.managedObjectContext else {
            preconditionFailure("Blog` with no `NSManagedObjectContext` attatched was passed to `StatsRecord.record(from:_for:_)`. This is an error.")
        }

        let recordType = TimeIntervalType.recordType
        let parentRecord: StatsRecord

        if let record = self.timeIntervalData(for: blog, type: recordType, period: timeIntervalData.recordPeriodType, date: timeIntervalData.date) {
            parentRecord = record
        } else {
            parentRecord = StatsRecord(context: managedObjectContext)
            parentRecord.blog = blog
            parentRecord.period = timeIntervalData.recordPeriodType.rawValue
            parentRecord.date = Calendar.autoupdatingCurrent.startOfDay(for: timeIntervalData.date) as NSDate
            parentRecord.type = recordType.rawValue
        }

        parentRecord.recordValues.forEach { managedObjectContext.deleteObject($0) }

        parentRecord.addToValues(NSOrderedSet(array: timeIntervalData.statsRecordValues(in: managedObjectContext)))

        parentRecord.fetchedDate = Date() as NSDate

        return parentRecord
    }


}
