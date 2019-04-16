import Foundation
import CoreData


public class AnnualAndMostPopularTimeStatsRecordValue: StatsRecordValue {
    public override func validateForInsert() throws {
        try super.validateForInsert()
        try recordValueSingleValueValidation()
    }
}

extension StatsAnnualAndMostPopularTimeInsight: StatsRecordValueConvertible {
    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
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

        return [value]
    }

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let insight = statsRecordValues.first as? AnnualAndMostPopularTimeStatsRecordValue
            else {
                return nil
        }

        let dayOfWeekComponent = DateComponents(weekday: Int(insight.mostPopularDayOfWeek))
        let hourComponent = DateComponents(hour: Int(insight.mostPopularHour))

        self = StatsAnnualAndMostPopularTimeInsight(mostPopularDayOfWeek: dayOfWeekComponent,
                                                    mostPopularDayOfWeekPercentage: Int(insight.mostPopularDayOfWeekPercentage),
                                                    mostPopularHour: hourComponent,
                                                    mostPopularHourPercentage: Int(insight.mostPopularHourPercentage),

                                                    annualInsightsYear: Int(insight.insightYear),
                                                    annualInsightsTotalPostsCount: Int(insight.totalPostsCount),

                                                    annualInsightsTotalWordsCount: Int(insight.totalWordsCount),
                                                    annualInsightsAverageWordsCount: insight.averageWordsCount,

                                                    annualInsightsTotalLikesCount: Int(insight.totalLikesCount),
                                                    annualInsightsAverageLikesCount: insight.averageLikesCount,

                                                    annualInsightsTotalCommentsCount: Int(insight.totalCommentsCount),
                                                    annualInsightsAverageCommentsCount: insight.averageCommentsCount,

                                                    annualInsightsTotalImagesCount: Int(insight.totalImagesCount),
                                                    annualInsightsAverageImagesCount: insight.averageImagesCount)
    }

    static var recordType: StatsRecordType {
        return .annualAndMostPopularTimes
    }


}
