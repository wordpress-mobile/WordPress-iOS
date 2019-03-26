import Foundation
import CoreData


public class SearchResultsStatsRecordValue: StatsRecordValue {

    /// This is a magic value indicating that this item represents search result counts for
    /// unknown/encrypted search terms.
    static let unknownSearchTermString = "WPiOS.search_string_unknown"
    // specific value here is mostly irrelevant, but I wanted to choose something that's REALLY
    // unlikely to show-up as a searched string — I could conceivably someone duckduckgoing
    // for things like "unknown search string" and landing on some SEO-explanation-blog.

}

extension StatsSearchTermTimeIntervalData: TimeIntervalStatsRecordValueConvertible {
    var recordPeriodType: StatsRecordPeriodType {
        return StatsRecordPeriodType(remoteStatus: period)
    }

    var date: Date {
        return periodEndDate
    }

    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        var searches: [StatsRecordValue] = searchTerms.map {
            let value = SearchResultsStatsRecordValue(context: context)

            value.searchTerm = $0.term
            value.viewsCount = Int64($0.viewsCount)

            return value
        }

        let hiddenSearches = SearchResultsStatsRecordValue(context: context)
        hiddenSearches.searchTerm = SearchResultsStatsRecordValue.unknownSearchTermString
        hiddenSearches.viewsCount = Int64(hiddenSearchTermsCount)

        searches.append(hiddenSearches)

        let otherAndTotalCount = OtherAndTotalViewsCountStatsRecordValue(context: context,
                                                                         otherCount: otherSearchTermsCount,
                                                                         totalCount: totalSearchTermsCount)

        searches.append(otherAndTotalCount)

        return searches
    }

    init?(statsRecordValues: [StatsRecordValue]) {
        guard
            let firstParent = statsRecordValues.first?.statsRecord,
            let period = StatsRecordPeriodType(rawValue: firstParent.period),
            let date = firstParent.date,
            let otherAndTotalCount = statsRecordValues.compactMap({ $0 as? OtherAndTotalViewsCountStatsRecordValue }).first
            else {
                return nil
        }


        var searchTerms: [StatsSearchTerm] = statsRecordValues
            .compactMap { $0 as? SearchResultsStatsRecordValue }
            .compactMap {
                guard
                    let term = $0.searchTerm
                    else {
                        return nil
                }

                return StatsSearchTerm(term: term, viewsCount: Int($0.viewsCount))
        }

        let unknownSearchCount: Int

        if let unknownSearchesIndex = searchTerms.firstIndex(where: { $0.term == SearchResultsStatsRecordValue.unknownSearchTermString }) {
            unknownSearchCount = searchTerms.remove(at: unknownSearchesIndex).viewsCount
        } else {
            unknownSearchCount = 0
        }

        self = StatsSearchTermTimeIntervalData(period: period.statsPeriodUnitValue,
                                               periodEndDate: date as Date,
                                               searchTerms: searchTerms,
                                               totalSearchTermsCount: Int(otherAndTotalCount.totalCount),
                                               hiddenSearchTermsCount: unknownSearchCount,
                                               otherSearchTermsCount: Int(otherAndTotalCount.otherCount))
    }

    static var recordType: StatsRecordType {
        return .searchTerms
    }

}
