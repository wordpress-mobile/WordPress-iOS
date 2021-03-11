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
        return Publishers.Zip(getTotalFollowerCount(), getDraftCount())
            .map { (followerCount, draftCount) -> [BlogHighlight] in
                var highlights: [BlogHighlight] = [.followers(followerCount)]
                if draftCount > 0 {
                    highlights.append(.drafts(draftCount))
                }
                return highlights
            }
            .eraseToAnyPublisher()
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
