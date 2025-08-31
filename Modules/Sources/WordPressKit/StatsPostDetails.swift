import Foundation

public struct StatsPostDetails: Equatable {
    public let fetchedDate: Date
    public let totalViewsCount: Int

    public let recentWeeks: [StatsWeeklyBreakdown]
    public let dailyAveragesPerMonth: [StatsPostViews]
    public let monthlyBreakdown: [StatsPostViews]
    public let lastTwoWeeks: [StatsPostViews]
    public let data: [StatsPostViews]

    public let highestMonth: Int?
    public let highestDayAverage: Int?
    public let highestWeekAverage: Int?

    public let yearlyTotals: [Int: Int]
    public let overallAverages: [Int: Int]

    public let fields: [String]?

    public let post: Post?

    public struct Post: Equatable {
        public let postID: Int
        public let title: String
        public let authorID: String?
        public let dateGMT: Date?
        public let content: String?
        public let excerpt: String?
        public let status: String?
        public let commentStatus: String?
        public let password: String?
        public let name: String?
        public let modifiedGMT: Date?
        public let contentFiltered: String?
        public let parent: Int?
        public let guid: String?
        public let type: String?
        public let mimeType: String?
        public let commentCount: String?
        public let permalink: String?

        init?(jsonDictionary: [String: AnyObject]) {
            guard
                let postID = jsonDictionary["ID"] as? Int,
                let title = jsonDictionary["post_title"] as? String
            else {
                return nil
            }

            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            var dateGMT: Date?
            var modifiedGMT: Date?

            if let postDateGMTString = jsonDictionary["post_date_gmt"] as? String {
                dateGMT = dateFormatter.date(from: postDateGMTString)
            }
            if let postModifiedGMTString = jsonDictionary["post_modified_gmt"] as? String {
                modifiedGMT = dateFormatter.date(from: postModifiedGMTString)
            }

            self.postID = postID
            self.title = title
            self.authorID = jsonDictionary["post_author"] as? String
            self.dateGMT = dateGMT
            self.content = jsonDictionary["post_content"] as? String
            self.excerpt = jsonDictionary["post_excerpt"] as? String
            self.status = jsonDictionary["post_status"] as? String
            self.commentStatus = jsonDictionary["comment_status"] as? String
            self.password = jsonDictionary["post_password"] as? String
            self.name = jsonDictionary["post_name"] as? String
            self.modifiedGMT = modifiedGMT
            self.contentFiltered = jsonDictionary["post_content_filtered"] as? String
            self.parent = jsonDictionary["post_parent"] as? Int
            self.guid = jsonDictionary["guid"] as? String
            self.type = jsonDictionary["post_type"] as? String
            self.mimeType = jsonDictionary["post_mime_type"] as? String
            self.commentCount = jsonDictionary["comment_count"] as? String
            self.permalink = jsonDictionary["permalink"] as? String
        }
    }
}

public struct StatsWeeklyBreakdown: Equatable {
    public let startDay: DateComponents
    public let endDay: DateComponents

    public let totalViewsCount: Int
    public let averageViewsCount: Int
    public let changePercentage: Double
    public let isChangeInfinity: Bool

    public let days: [StatsPostViews]
}

public struct StatsPostViews: Equatable {
    public let period: StatsPeriodUnit
    public let date: DateComponents
    public let viewsCount: Int
}

extension StatsPostDetails {
    public init?(jsonDictionary: [String: AnyObject]) {
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

        self.data = StatsPostViews.mapDailyData(data: data)

        // It's very hard to describe the format of this response. I tried to make the parsing
        // as nice and readable as possible, but in all honestly it's still pretty nasty.
        // If you want to see an example response to see how weird this response is, check out
        // `stats-post-details.json`.
        self.recentWeeks = StatsPostViews.mapWeeklyBreakdown(jsonDictionary: recentWeeks)
        self.monthlyBreakdown = StatsPostViews.mapMonthlyBreakdown(jsonDictionary: monthlyBreakdown)
        self.dailyAveragesPerMonth = StatsPostViews.mapMonthlyBreakdown(jsonDictionary: monthlyAverages)
        self.lastTwoWeeks = StatsPostViews.mapDailyData(data: Array(data.suffix(14)))

        // Parse new fields
        self.highestMonth = jsonDictionary["highest_month"] as? Int
        self.highestDayAverage = jsonDictionary["highest_day_average"] as? Int
        self.highestWeekAverage = jsonDictionary["highest_week_average"] as? Int

        self.fields = jsonDictionary["fields"] as? [String]

        // Parse yearly totals
        var yearlyTotals: [Int: Int] = [:]
        if let years = monthlyBreakdown as? [String: [String: AnyObject]] {
            for (yearKey, yearData) in years {
                if let yearInt = Int(yearKey), let total = yearData["total"] as? Int {
                    yearlyTotals[yearInt] = total
                }
            }
        }
        self.yearlyTotals = yearlyTotals

        // Parse overall averages
        var overallAverages: [Int: Int] = [:]
        if let averages = monthlyAverages as? [String: [String: AnyObject]] {
            for (yearKey, yearData) in averages {
                if let yearInt = Int(yearKey), let overall = yearData["overall"] as? Int {
                    overallAverages[yearInt] = overall
                }
            }
        }
        self.overallAverages = overallAverages

        // Parse post object using the new Post model
        if let postDict = jsonDictionary["post"] as? [String: AnyObject] {
            self.post = Post(jsonDictionary: postDict)
        } else {
            self.post = nil
        }
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

            var change: Double = 0.0
            var isChangeInfinity = false

            if let changeValue = $0["change"] {
                if let changeDict = changeValue as? [String: AnyObject],
                   let isInfinity = changeDict["isInfinity"] as? Bool {
                    isChangeInfinity = isInfinity
                    change = isInfinity ? Double.infinity : 0.0
                } else if let changeDouble = changeValue as? Double {
                    change = changeDouble
                }
            }

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
                                        isChangeInfinity: isChangeInfinity,
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
