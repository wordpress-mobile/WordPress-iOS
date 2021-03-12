import Foundation
import Combine

class BlogHighlightsService: LocalCoreDataService {

    // MARK: - Properties

    private let blog: Blog

    // MARK: - Properties (Services)

    private lazy var statsService: StatsServiceRemoteV2? = {
        guard let siteID = blog.dotComID?.intValue else {
                DDLogError("Blog must have a valid ID")
                return nil
        }
        let wpApi = WordPressComRestApi(oAuthToken: blog.authToken)
        return StatsServiceRemoteV2(wordPressComRestApi: wpApi, siteID: siteID, siteTimezone: blog.timeZone)
    }()

    private lazy var postService: PostServiceRemote? = {
        return PostServiceRemoteFactory().forBlog(blog)
    }()

    // MARK: - Init

    init(blog: Blog) {
        self.blog = blog
        super.init()
    }

    // MARK: - Get highlights

    func getHighlights() -> AnyPublisher<[BlogHighlight], Never> {
        return Publishers.Zip3(getTotalFollowerCount(), getDraftCount(), getViewCountDelta(for: .day))
            .map { (followerCount, draftCount, viewCountDelta) -> [BlogHighlight] in
                var highlights: [BlogHighlight] = [.followers(followerCount)]

                if let viewCountDelta = viewCountDelta, viewCountDelta != 0 {
                    highlights.append(.views(viewCountDelta))
                }

                if draftCount > 0 {
                    highlights.append(.drafts(draftCount))
                }

                return highlights
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Get view count delta

    func getViewCountDelta(for interval: StatsPeriodUnit) -> AnyPublisher<Int?, Never> {
        return getSummaryIntervalData(for: interval)
            .map { (intervalData) -> Int? in
                guard let summaryData = intervalData?.summaryData else {
                    return nil
                }

                let currentPeriodViewCount = summaryData[1].viewsCount
                let previousPeriodViewCount = summaryData[0].viewsCount

                let delta = currentPeriodViewCount - previousPeriodViewCount
                var roundedPercentage = 0

                if previousPeriodViewCount > 0 {
                    let percentage = (Float(delta) / Float(previousPeriodViewCount)) * 100
                    roundedPercentage = Int(round(percentage))
                }

                return roundedPercentage
            }
            .eraseToAnyPublisher()
    }

    private func getSummaryIntervalData(for interval: StatsPeriodUnit) -> Future<StatsSummaryTimeIntervalData?, Never> {
        let now = Date()
        return Future { [weak self] promise in
            self?.statsService?.getData(for: interval, endingOn: now, limit: 2, completion: { (data: StatsSummaryTimeIntervalData?, error) in
                promise(.success(data))
            })
        }
    }

    // MARK: - Get draft count

    private func getDraftCount() -> AnyPublisher<Int, Never> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            self.postService?.getPostsOfType("post", success: { (posts) in
                let drafts = posts?.filter { $0.status == PostStatusDraft }
                promise(.success(drafts?.count ?? 0))
            }, failure: { (error) in
                DDLogError("Error fetching drafts: \(String(describing: error?.localizedDescription))")
            })
        }.eraseToAnyPublisher()
    }

    // MARK: - Get follower count

    private func getTotalFollowerCount() -> AnyPublisher<Int, Never> {
        return Publishers.Merge3(getWpComFollowerCount(), getEmailFollowerCount(), getPublicizeFollowerCount())
            .collect()
            .map { $0.reduce(0, +) }
            .eraseToAnyPublisher()
    }

    private func getWpComFollowerCount() -> Future<Int, Never> {
        return Future { [weak self] promise in
            self?.statsService?.getInsight { (wpComFollowers: StatsDotComFollowersInsight?, error) in
                promise(.success(wpComFollowers?.dotComFollowersCount ?? 0))
            }
        }
    }

    private func getEmailFollowerCount() -> Future<Int, Never> {
        return Future { [weak self] promise in
            self?.statsService?.getInsight { (emailFollowers: StatsEmailFollowersInsight?, error) in
                promise(.success(emailFollowers?.emailFollowersCount ?? 0))
            }
        }
    }

    private func getPublicizeFollowerCount() -> Future<Int, Never> {
        return Future { [weak self] promise in
            self?.statsService?.getInsight { (publicizeInsight: StatsPublicizeInsight?, error) in
                let publicizeFollowers = publicizeInsight?.publicizeServices.compactMap({$0.followers}).reduce(0, +)
                promise(.success(publicizeFollowers ?? 0))
            }
        }
    }
}
