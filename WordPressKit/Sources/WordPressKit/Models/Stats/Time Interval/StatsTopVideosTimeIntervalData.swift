public struct StatsTopVideosTimeIntervalData {
    public let period: StatsPeriodUnit
    public let periodEndDate: Date

    public let totalPlaysCount: Int
    public let otherPlayCount: Int
    public let videos: [StatsVideo]

    public init(period: StatsPeriodUnit,
                periodEndDate: Date,
                videos: [StatsVideo],
                totalPlaysCount: Int,
                otherPlayCount: Int) {
        self.period = period
        self.periodEndDate = periodEndDate
        self.videos = videos
        self.totalPlaysCount = totalPlaysCount
        self.otherPlayCount = otherPlayCount
    }
}

public struct StatsVideo {
    public let postID: Int
    public let title: String
    public let playsCount: Int
    public let videoURL: URL?

    public init(postID: Int,
                title: String,
                playsCount: Int,
                videoURL: URL?) {
        self.postID = postID
        self.title = title
        self.playsCount = playsCount
        self.videoURL = videoURL
    }
}

extension StatsTopVideosTimeIntervalData: StatsTimeIntervalData {

    public static var pathComponent: String {
        return "stats/video-plays"
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        guard
            let unwrappedDays = type(of: self).unwrapDaysDictionary(jsonDictionary: jsonDictionary),
            let totalPlayCount = unwrappedDays["total_plays"] as? Int,
            let otherPlays = unwrappedDays["other_plays"] as? Int,
            let videos = unwrappedDays["plays"] as? [[String: AnyObject]]
            else {
                return nil
        }

        self.period = period
        self.periodEndDate = date
        self.totalPlaysCount = totalPlayCount
        self.otherPlayCount = otherPlays
        self.videos = videos.compactMap { StatsVideo(jsonDictionary: $0) }
    }
}

extension StatsVideo {
    init?(jsonDictionary: [String: AnyObject]) {
        guard
            let postID = jsonDictionary["post_id"] as? Int,
            let title = jsonDictionary["title"] as? String,
            let playsCount = jsonDictionary["plays"] as? Int,
            let url = jsonDictionary["url"] as? String
            else {
                return nil
        }

        self.postID = postID
        self.title = title
        self.playsCount = playsCount
        self.videoURL = URL(string: url)
    }
}
