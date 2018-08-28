/// Abstract stats tracking
protocol NewsStats {
    func trackPresented(news: Result<NewsItem>?)
    func trackDismissed(news: Result<NewsItem>?)
    func trackRequestedExtendedInfo(news: Result<NewsItem>?)
}

/// Implementation of the NewsStats protocol that provides Tracks integration for the NewsCard
final class TracksNewsStats: NewsStats {
    private let origin: String

    enum StatsKeys {
        static let origin = "origin"
        static let version = "version"
    }

    init(origin: String) {
        self.origin = origin
    }

    func trackPresented(news: Result<NewsItem>?) {
        track(event: .newsCardViewed, news: news)
    }

    func trackDismissed(news: Result<NewsItem>?) {
        track(event: .newsCardDismissed, news: news)
    }

    func trackRequestedExtendedInfo(news: Result<NewsItem>?) {
        track(event: .newsCardRequestedExtendedInfo, news: news)
    }

    private func eventProperties(version: Decimal) -> [AnyHashable: Any] {
        return [StatsKeys.origin: origin,
                StatsKeys.version: version.description]
    }

    private func track(event: WPAnalyticsStat, news: Result<NewsItem>?) {
        guard let actualNews = news else {
            return
        }

        switch actualNews {
        case .error:
            return
        case .success(let newsItem):
            WPAppAnalytics.track(event, withProperties: eventProperties(version: newsItem.version))
        }
    }

}
