public struct StatsPostingStreakInsight: Equatable, Codable {
    public let streaks: PostingStreaks
    public let postingEvents: [PostingStreakEvent]

    public var currentStreakStart: Date? {
        streaks.current?.start
    }

    public var currentStreakEnd: Date? {
        streaks.current?.end
    }
    public var currentStreakLength: Int? {
        streaks.current?.length
    }

    public var longestStreakStart: Date? {
        streaks.long?.start ?? currentStreakStart
    }
    public var longestStreakEnd: Date? {
        streaks.long?.end ?? currentStreakEnd
    }

    public var longestStreakLength: Int? {
        streaks.long?.length ?? currentStreakLength
    }

    private enum CodingKeys: String, CodingKey {
        case streaks = "streak"
        case postingEvents = "data"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.streaks = try container.decode(PostingStreaks.self, forKey: .streaks)
        let postsData = (try? container.decodeIfPresent([String: Int].self, forKey: .postingEvents)) ?? [:]

        let postingDates = postsData.keys
            .compactMap { Double($0) }
            .map { Date(timeIntervalSince1970: $0) }
            .map { Calendar.autoupdatingCurrent.startOfDay(for: $0) }

        if postingDates.isEmpty {
            self.postingEvents = []
        } else {
            let countedPosts = NSCountedSet(array: postingDates)
            self.postingEvents = countedPosts.compactMap { value in
                if let date = value as? Date {
                    return PostingStreakEvent(date: date, postCount: countedPosts.count(for: value))
                } else {
                    return nil
                }
            }
        }
    }
}

public struct PostingStreakEvent: Equatable, Codable {
    public let date: Date
    public let postCount: Int

    public init(date: Date, postCount: Int) {
        self.date = date
        self.postCount = postCount
    }
}

public struct PostingStreaks: Equatable, Codable {
    public let long: PostingStreak?
    public let current: PostingStreak?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.long = try? container.decodeIfPresent(PostingStreak.self, forKey: .long)
        self.current = try? container.decodeIfPresent(PostingStreak.self, forKey: .current)
    }
}

public struct PostingStreak: Equatable, Codable {
    public let start: Date
    public let end: Date
    public let length: Int

    private enum CodingKeys: String, CodingKey {
        case start
        case end
        case length
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let startValue = try container.decode(String.self, forKey: .start)
        if let start = StatsPostingStreakInsight.dateFormatter.date(from: startValue) {
            self.start = start
        } else {
            throw DecodingError.dataCorruptedError(forKey: .start, in: container, debugDescription: "Start date string doesn't match expected format")
        }

        let endValue = try container.decode(String.self, forKey: .end)
        if let end = StatsPostingStreakInsight.dateFormatter.date(from: endValue) {
            self.end = end
        } else {
            throw DecodingError.dataCorruptedError(forKey: .end, in: container, debugDescription: "End date string doesn't match expected format")
        }

        length = try container.decodeIfPresent(Int.self, forKey: .length) ?? 0
    }
}

extension StatsPostingStreakInsight: StatsInsightData {

    // MARK: - StatsInsightData Conformance
    public static var pathComponent: String {
        return "stats/streak"
    }

    // Some heavy-traffic sites can have A LOT of posts and the default query parameters wouldn't
    // return all the relevant streak data, so we manualy override the `max` and `startDate``/endDate`
    // parameters to hopefully get all.
    public static var queryProperties: [String: String] {
        let today = Date()

        let numberOfDaysInCurrentMonth = Calendar.autoupdatingCurrent.range(of: .day, in: .month, for: today)

        guard
            let firstDayIndex = numberOfDaysInCurrentMonth?.first,
            let lastDayIndex = numberOfDaysInCurrentMonth?.last,
            let lastDayOfMonth = Calendar.autoupdatingCurrent.date(bySetting: .day, value: lastDayIndex, of: today),
            let firstDayOfMonth = Calendar.autoupdatingCurrent.date(bySetting: .day, value: firstDayIndex, of: today),
            let yearAgo = Calendar.autoupdatingCurrent.date(byAdding: .year, value: -1, to: firstDayOfMonth)
            else {
                return [:]
        }

        let firstDayString = self.dateFormatter.string(from: yearAgo)
        let lastDayString = self.dateFormatter.string(from: lastDayOfMonth)

        return ["startDate": "\(firstDayString)",
                "endDate": "\(lastDayString)",
                "max": "5000"]
    }

    fileprivate static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
