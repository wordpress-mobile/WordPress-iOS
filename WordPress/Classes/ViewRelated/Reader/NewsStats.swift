///// Abstract stats tracking
//remove news card
//protocol NewsStats {
//    func trackPresented(news: Result<NewsItem, Error>?)
//    func trackDismissed(news: Result<NewsItem, Error>?)
//    func trackRequestedExtendedInfo(news: Result<NewsItem, Error>?)
//}
//
///// Implementation of the NewsStats protocol that provides Tracks integration for the NewsCard
//final class TracksNewsStats: NewsStats {
//    private let origin: String
//
//    enum StatsKeys {
//        static let origin = "origin"
//        static let version = "version"
//    }
//
//    init(origin: String) {
//        self.origin = origin
//    }
//
//    func trackPresented(news: Result<NewsItem, Error>?) {
//        track(event: .newsCardViewed, news: news)
//    }
//
//    func trackDismissed(news: Result<NewsItem, Error>?) {
//        track(event: .newsCardDismissed, news: news)
//    }
//
//    func trackRequestedExtendedInfo(news: Result<NewsItem, Error>?) {
//        track(event: .newsCardRequestedExtendedInfo, news: news)
//    }
//
//    private func eventProperties(version: Decimal) -> [AnyHashable: Any] {
//        return [StatsKeys.origin: origin,
//                StatsKeys.version: version.description]
//    }
//
//    private func track(event: WPAnalyticsStat, news: Result<NewsItem, Error>?) {
//        guard let actualNews = news else {
//            return
//        }
//
//        switch actualNews {
//        case .failure:
//            return
//        case .success(let newsItem):
//            WPAppAnalytics.track(event, withProperties: eventProperties(version: newsItem.version))
//        }
//    }
//
//}
