import Foundation
import WordPressComStatsiOS

/// The view model used by Stats Insights.
///
class SiteStatsInsightsViewModel: NSObject {

    // MARK: - Properties

    private var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?

    // MARK: - Constructor

    init(insightsDelegate: SiteStatsInsightsDelegate) {
        super.init()
        self.siteStatsInsightsDelegate = insightsDelegate
    }

    // MARK: - Data Fetching

    func fetchStats() {

        SiteStatsInformation.statsService()?.retrieveInsightsStats(allTimeStatsCompletionHandler: { (allTimeStats, error) in

        }, insightsCompletionHandler: { (mostPopularStats, error) in

        }, todaySummaryCompletionHandler: { (todaySummary, error) in

        }, latestPostSummaryCompletionHandler: { (latestPostSummary, error) in
            if error != nil {
                DDLogDebug("Error fetching latest post summary: \(String(describing: error?.localizedDescription))")
            }

            self.siteStatsInsightsDelegate?.latestPostSummaryLoaded?(latestPostSummary)
        }, commentsAuthorCompletionHandler: { (commentsAuthors, error) in

        }, commentsPostsCompletionHandler: { (commentsPosts, error) in

        }, tagsCategoriesCompletionHandler: { (tagsCategories, error) in

        }, followersDotComCompletionHandler: { (followersDotCom, error) in

        }, followersEmailCompletionHandler: { (followersEmail, error) in

        }, publicizeCompletionHandler: { (publicize, error) in

        }, streakCompletionHandler: { (statsStreak, error) in

        }, progressBlock: { (numberOfFinishedOperations, totalNumberOfOperations) in

        }, andOverallCompletionHandler: {

        })
    }

}
