public struct StatsPostDetails: Equatable {
    public let fetchedDate: Date
    public let totalViewsCount: Int

    public let recentWeeks: [StatsWeeklyBreakdown]
    public let dailyAveragesPerMonth: [StatsPostViews]
    public let monthlyBreakdown: [StatsPostViews]
    public let lastTwoWeeks: [StatsPostViews]
}

public struct StatsWeeklyBreakdown: Equatable {
    public let startDay: DateComponents
    public let endDay: DateComponents

    public let totalViewsCount: Int
    public let averageViewsCount: Int
    public let changePercentage: Double

    public let days: [StatsPostViews]
}

public struct StatsPostViews: Equatable {
    public let period: StatsPeriodUnit
    public let date: DateComponents
    public let viewsCount: Int
}

extension StatsPostDetails {
    init?(jsonDictionary: [String: AnyObject]) {
        guard
            let fetchedDateString = jsonDictionary["date"] as? String,
            let date = type(of: self).dateFormatter.date(from: fetchedDateString),
            let totalViewsCount = jsonDictionary["views"] as? Int,
            let monthlyBreakdown = jsonDictionary["years"] as? [String: AnyObject],
            let monthlyAverages = jsonDictionary["averages"] as? [String: AnyObject],
            let recentWeeks = jsonDictionary["weeks"] as? [[String: AnyObject]],
            let data = jsonDictionary["data"] as? [[Any]]
            else {
                return nil
        }

        self.fetchedDate = date
        self.totalViewsCount = totalViewsCount

        // It's very hard to describe the format of this response. I tried to make the parsing
        // as nice and readable as possible, but in all honestly it's still pretty nasty.
        // If you want to see an example response to see how weird this response is, check out
        // `stats-post-details.json`.
        self.recentWeeks = StatsPostViews.mapWeeklyBreakdown(jsonDictionary: recentWeeks)
        self.monthlyBreakdown = StatsPostViews.mapMonthlyBreakdown(jsonDictionary: monthlyBreakdown)
        self.dailyAveragesPerMonth = StatsPostViews.mapMonthlyBreakdown(jsonDictionary: monthlyAverages)
        self.lastTwoWeeks = StatsPostViews.mapDailyData(data: Array(data.suffix(14)))
    }

    static var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POS")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }
}

extension StatsPostViews {
    static func mapMonthlyBreakdown(jsonDictionary: [String: AnyObject]) -> [StatsPostViews] {
        return jsonDictionary.flatMap { yearKey, value -> [StatsPostViews] in
            guard
                let yearInt = Int(yearKey),
                let monthsDict = value as? [String: AnyObject],
                let months = monthsDict["months"] as? [String: Int]
                else {
                    return []
            }

            return months.compactMap { monthKey, value in
                guard
                    let month = Int(monthKey)
                    else {
                        return nil
                }

                return StatsPostViews(period: .month,
                                      date: DateComponents(year: yearInt, month: month),
                                      viewsCount: value)
            }
        }
    }
}

extension StatsPostViews {
    static func mapWeeklyBreakdown(jsonDictionary: [[String: AnyObject]]) -> [StatsWeeklyBreakdown] {
        return jsonDictionary.compactMap {
            guard
                let totalViews = $0["total"] as? Int,
                let averageViews = $0["average"] as? Int,
                let days = $0["days"] as? [[String: AnyObject]]
                else {
                    return nil
            }

            let change = ($0["change"] as? Double) ?? 0.0

            let mappedDays: [StatsPostViews] = days.compactMap {
                guard
                    let dayString = $0["day"] as? String,
                    let date = StatsPostDetails.dateFormatter.date(from: dayString),
                    let viewsCount = $0["count"] as? Int
                    else {
                        return nil
                }

                return StatsPostViews(period: .day,
                                      date: Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: date),
                                      viewsCount: viewsCount)
            }

            guard !mappedDays.isEmpty else {
                return nil
            }

            return StatsWeeklyBreakdown(startDay: mappedDays.first!.date,
                                        endDay: mappedDays.last!.date,
                                        totalViewsCount: totalViews,
                                        averageViewsCount: averageViews,
                                        changePercentage: change,
                                        days: mappedDays)
        }

    }
}

extension StatsPostViews {
    static func mapDailyData(data: [[Any]]) -> [StatsPostViews] {
        return data.compactMap {
            guard
                let dateString = $0[0] as? String,
                let date = StatsPostDetails.dateFormatter.date(from: dateString),
                let viewsCount = $0[1] as? Int
                else {
                    return nil
            }

            return StatsPostViews(period: .day,
                                  date: Calendar.autoupdatingCurrent.dateComponents([.year, .month, .day], from: date),
                                  viewsCount: viewsCount)
        }
    }
}
