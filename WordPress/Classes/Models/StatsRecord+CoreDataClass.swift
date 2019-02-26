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
    case topCommentAuthors
    case topCommentedPosts


    case blogVisitsSummary
    case clicks
    case countryViews
    case postViews
    case postingStreak
    case publishedPosts
    case referrers
    case searchTerms
    case topViewedPost
    case videos
    case topViewedAuthor

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
              .topCommentAuthors,
              .topCommentedPosts:

            return false
        case  .blogVisitsSummary,
              .clicks,
              .countryViews,
              .postingStreak,
              .publishedPosts,
              .referrers,
              .searchTerms,
              .topViewedAuthor,
              .topViewedPost,
              .videos,
              .postViews:

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
}


public class StatsRecord: NSManagedObject {

    public class func fetchRequest(for kind: StatsRecordType, on day: Date = Date()) -> NSFetchRequest<StatsRecord> {
        let fr: NSFetchRequest<StatsRecord> = self.fetchRequest()

        let calendar = Calendar.autoupdatingCurrent
        let rangeOfDay = calendar.dateInterval(of: .day, for: day)!

        let typePredicate = NSPredicate(format: "\(#keyPath(StatsRecord.type)) = %i", kind.rawValue)

        guard kind.requiresDate else {
            fr.predicate = typePredicate
            return fr
        }

        let dateStartPredicate = NSPredicate(format: "\(#keyPath(StatsRecord.date)) >= %@", rangeOfDay.start as NSDate)
        let dateEndPredicate = NSPredicate(format: "\(#keyPath(StatsRecord.date)) <= %@", rangeOfDay.end as NSDate)

        fr.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            typePredicate,
            NSCompoundPredicate(andPredicateWithSubpredicates: [dateStartPredicate,
                                                               dateEndPredicate])])

        return fr
    }

    public override func validateForInsert() throws {
        try super.validateForInsert()

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
            try singleEntryTypeValidation()

            guard period == StatsRecordPeriodType.notApplicable.rawValue else {
                throw StatsCoreDataValidationError.invalidPeriod
            }
        }
    }
}

public enum StatsCoreDataValidationError: Error {

    case incorrectRecordType
    case noManagedObjectContext
    case noDate
    case invalidPeriod
    case invalidEnumValue

    /// Thrown when trying to insert a second instance of a type that only supports
    /// a single entry being present in the Core Data store.
    case singleEntryTypeViolation
}

extension NSManagedObject {
    public func singleEntryTypeValidation() throws {
        guard let moc = managedObjectContext else {
            throw StatsCoreDataValidationError.noManagedObjectContext
        }

        let existingObjectsCount = try moc.count(for: type(of: self).fetchRequest())

        guard existingObjectsCount == 1 else {
            throw StatsCoreDataValidationError.singleEntryTypeViolation
        }
    }
}
