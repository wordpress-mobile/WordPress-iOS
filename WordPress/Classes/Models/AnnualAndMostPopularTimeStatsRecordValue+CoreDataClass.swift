import Foundation
import CoreData


public class AnnualAndMostPopularTimeStatsRecordValue: StatsRecordValue {
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try singleEntryTypeValidation()
    }
}

extension StatsAnnualAndMostPopularTimeInsight: StatsRecordValueConvertible {
    func statsRecordValue(in context: NSManagedObjectContext) -> StatsRecordValue {
        let value = AnnualAndMostPopularTimeStatsRecordValue(context: context)

        value.mostPopularDayOfWeek = Int64(self.mostPopularDayOfWeek.weekday!)
        value.mostPopularDayOfWeekPercentage = Int64(self.mostPopularDayOfWeekPercentage)

        value.mostPopularHour = Int64(self.mostPopularHour.hour!)
        value.mostPopularHourPercentage = Int64(self.mostPopularHourPercentage)

        value.insightYear = Int64(self.annualInsightsYear)

        value.totalPostsCount = Int64(self.annualInsightsTotalPostsCount)

        value.totalWordsCount = Int64(self.annualInsightsTotalWordsCount)
        value.averageWordsCount = self.annualInsightsAverageWordsCount

        value.totalLikesCount = Int64(self.annualInsightsTotalLikesCount)
        value.averageLikesCount = self.annualInsightsAverageLikesCount

        value.totalCommentsCount = Int64(self.annualInsightsTotalCommentsCount)
        value.averageCommentsCount = self.annualInsightsAverageCommentsCount

        value.totalImagesCount = Int64(self.annualInsightsTotalImagesCount)
        value.averageImagesCount = self.annualInsightsAverageImagesCount

        return value
    }

    init(statsRecordValue: StatsRecordValue) {
        // We won't be needing those until later. I added them to protocol to show the intended design
        // but it doesn't make sense to implement it yet.
        fatalError("This shouldn't be called yet — implementation of StatsRecordValueConvertible is still in progres. This method was added to illustrate intended design, but isn't ready yet.")
    }

    static var recordType: StatsRecordType {
        return .annualAndMostPopularTimes
    }


}
