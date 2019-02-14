import Foundation
import CoreData


extension AnnualAndMostPopularTimeStatsRecordValue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AnnualAndMostPopularTimeStatsRecordValue> {
        return NSFetchRequest<AnnualAndMostPopularTimeStatsRecordValue>(entityName: "AnnualAndMostPopularTimeStatsRecordValue")
    }

    @NSManaged public var mostPopularDayOfWeek: Int64
    @NSManaged public var mostPopularDayOfWeekPercentage: Int64
    @NSManaged public var mostPopularHour: Int64
    @NSManaged public var mostPopularHourPercentage: Int64
    @NSManaged public var insightYear: Int64
    @NSManaged public var totalPostsCount: Int64
    @NSManaged public var totalWordsCount: Int64
    @NSManaged public var averageWordsCount: Double
    @NSManaged public var totalLikesCount: Int64
    @NSManaged public var averageLikesCount: Double
    @NSManaged public var totalCommentsCount: Int64
    @NSManaged public var averageCommentsCount: Double
    @NSManaged public var totalImagesCount: Int64
    @NSManaged public var averageImagesCount: Double

}
