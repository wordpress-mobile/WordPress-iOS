import Foundation
import CoreData


public class CountryStatsRecordValue: StatsRecordValue {

}

extension StatsTopCountryTimeIntervalData: TimeIntervalStatsRecordValueConvertible {
    var recordPeriodType: StatsRecordPeriodType {
        return StatsRecordPeriodType(remoteStatus: period)
    }

    var date: Date {
        return periodEndDate
    }

    func statsRecordValues(in context: NSManagedObjectContext) -> [StatsRecordValue] {
        var mappedCountries: [StatsRecordValue] = countries.map {
            let value = CountryStatsRecordValue(context: context)

            value.countryCode = $0.code
            value.countryName = $0.name
            value.viewsCount = Int64($0.viewsCount)

            return value
        }

        let otherAndTotalCount = OtherAndTotalViewsCountStatsRecordValue(context: context,
                                                                         otherCount: otherViewsCount,
                                                                         totalCount: totalViewsCount)

        mappedCountries.append(otherAndTotalCount)

        return mappedCountries
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


        let countries: [StatsCountry] = statsRecordValues
            .compactMap { $0 as? CountryStatsRecordValue }
            .compactMap {
                guard
                    let code = $0.countryCode,
                    let name = $0.countryName
                    else {
                        return nil
                }

                return StatsCountry(name: name, code: code, viewsCount: Int($0.viewsCount))
        }

        self = StatsTopCountryTimeIntervalData(period: period.statsPeriodUnitValue,
                                               periodEndDate: date as Date,
                                               countries: countries,
                                               totalViewsCount: Int(otherAndTotalCount.totalCount),
                                               otherViewsCount: Int(otherAndTotalCount.otherCount))
    }

    static var recordType: StatsRecordType {
        return .countryViews
    }

}
