@objc enum StatSection: Int {
    case periodOverviewViews
    case periodOverviewVisitors
    case periodOverviewLikes
    case periodOverviewComments
    case periodPostsAndPages
    case periodReferrers
    case periodClicks
    case periodAuthors
    case periodCountries
    case periodSearchTerms
    case periodPublished
    case periodVideos
    case periodFileDownloads
    case insightsLatestPostSummary
    case insightsAllTime
    case insightsFollowerTotals
    case insightsMostPopularTime
    case insightsTagsAndCategories
    case insightsAnnualSiteStats
    case insightsCommentsAuthors
    case insightsCommentsPosts
    case insightsFollowersWordPress
    case insightsFollowersEmail
    case insightsTodaysStats
    case insightsPostingActivity
    case insightsPublicize
    case insightsAddInsight
    case postStatsGraph
    case postStatsMonthsYears
    case postStatsAverageViews
    case postStatsRecentWeeks

    static let allInsights = [StatSection.insightsLatestPostSummary,
                              .insightsAllTime,
                              .insightsFollowerTotals,
                              .insightsMostPopularTime,
                              .insightsTagsAndCategories,
                              .insightsAnnualSiteStats,
                              .insightsCommentsAuthors,
                              .insightsCommentsPosts,
                              .insightsFollowersWordPress,
                              .insightsFollowersEmail,
                              .insightsTodaysStats,
                              .insightsPostingActivity,
                              .insightsPublicize
    ]

    static let allPeriods = [StatSection.periodOverviewViews,
                             .periodOverviewVisitors,
                             .periodOverviewLikes,
                             .periodOverviewComments,
                             .periodPostsAndPages,
                             .periodReferrers,
                             .periodClicks,
                             .periodAuthors,
                             .periodCountries,
                             .periodSearchTerms,
                             .periodPublished,
                             .periodVideos,
                             .periodFileDownloads
    ]

    static let allPostStats = [StatSection.postStatsGraph,
                               .postStatsMonthsYears,
                               .postStatsAverageViews,
                               .postStatsRecentWeeks
    ]

    // MARK: - String Accessors

    var title: String {
        switch self {
        case .insightsLatestPostSummary:
            return InsightsHeaders.latestPostSummary
        case .insightsAllTime:
            return InsightsHeaders.allTimeStats
        case .insightsFollowerTotals:
            return InsightsHeaders.followerTotals
        case .insightsMostPopularTime:
            return InsightsHeaders.mostPopularTime
        case .insightsTagsAndCategories:
            return InsightsHeaders.tagsAndCategories
        case .insightsAnnualSiteStats:
            return InsightsHeaders.annualSiteStats
        case .insightsCommentsAuthors, .insightsCommentsPosts:
            return InsightsHeaders.comments
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            return InsightsHeaders.followers
        case .insightsTodaysStats:
            return InsightsHeaders.todaysStats
        case .insightsPostingActivity:
            return InsightsHeaders.postingActivity
        case .insightsPublicize:
            return InsightsHeaders.publicize
        case .insightsAddInsight:
            return InsightsHeaders.addCard
        case .periodPostsAndPages:
            return PeriodHeaders.postsAndPages
        case .periodReferrers:
            return PeriodHeaders.referrers
        case .periodClicks:
            return PeriodHeaders.clicks
        case .periodAuthors:
            return PeriodHeaders.authors
        case .periodCountries:
            return PeriodHeaders.countries
        case .periodSearchTerms:
            return PeriodHeaders.searchTerms
        case .periodPublished:
            return PeriodHeaders.published
        case .periodVideos:
            return PeriodHeaders.videos
        case .periodFileDownloads:
            return PeriodHeaders.fileDownloads
        case .postStatsMonthsYears:
            return PostStatsHeaders.monthsAndYears
        case .postStatsAverageViews:
            return PostStatsHeaders.averageViewsPerDay
        case .postStatsRecentWeeks:
            return PostStatsHeaders.recentWeeks
        default:
            return ""
        }
    }

    var itemSubtitle: String {
        switch self {
        case .insightsCommentsPosts,
             .insightsTagsAndCategories,
             .periodPostsAndPages,
             .periodVideos:
            return ItemSubtitles.title
        case .insightsCommentsAuthors,
             .periodAuthors:
            return ItemSubtitles.author
        case .insightsPublicize:
            return ItemSubtitles.service
        case .insightsFollowersWordPress,
             .insightsFollowersEmail:
            return ItemSubtitles.follower
        case .periodReferrers:
            return ItemSubtitles.referrer
        case .periodClicks:
            return ItemSubtitles.link
        case .periodCountries:
            return ItemSubtitles.country
        case .periodSearchTerms:
            return ItemSubtitles.searchTerm
        case .postStatsMonthsYears, .postStatsAverageViews, .postStatsRecentWeeks:
            return ItemSubtitles.period
        case .periodFileDownloads:
            return ItemSubtitles.file
        default:
            return ""
        }
    }

    var dataSubtitle: String {
        switch self {
        case .insightsCommentsAuthors,
             .insightsCommentsPosts:
            return DataSubtitles.comments
        case .insightsTagsAndCategories,
             .periodPostsAndPages,
             .periodReferrers,
             .periodAuthors,
             .periodCountries,
             .periodSearchTerms,
             .periodVideos,
             .postStatsMonthsYears,
             .postStatsAverageViews,
             .postStatsRecentWeeks:
            return DataSubtitles.views
        case .insightsPublicize:
            return DataSubtitles.followers
        case .insightsFollowersWordPress,
             .insightsFollowersEmail:
            return DataSubtitles.since
        case .periodClicks:
            return DataSubtitles.clicks
        case .periodFileDownloads:
            return DataSubtitles.downloads
        default:
            return ""
        }
    }

    var tabTitle: String {
        switch self {
        case .insightsCommentsAuthors:
            return TabTitles.commentsAuthors
        case .insightsCommentsPosts:
            return TabTitles.commentsPosts
        case .insightsFollowersWordPress:
            return TabTitles.followersWordPress
        case .insightsFollowersEmail:
            return TabTitles.followersEmail
        case .periodOverviewViews:
            return TabTitles.overviewViews
        case .periodOverviewVisitors:
            return TabTitles.overviewVisitors
        case .periodOverviewLikes:
            return TabTitles.overviewLikes
        case .periodOverviewComments:
            return TabTitles.overviewComments
        default:
            return ""
        }
    }

    var totalFollowers: String {
        switch self {
        case .insightsFollowersWordPress:
            return TotalFollowers.wordPress
        case .insightsFollowersEmail:
            return TotalFollowers.email
        default:
            return ""
        }
    }

    var detailsTitle: String {
        switch self {
        case .insightsAnnualSiteStats:
            return DetailsTitles.annualSiteStats
        default:
            return title
        }
    }

    var insightManagementTitle: String {
        switch self {
        case .insightsTodaysStats:
            return InsightManagementTitles.todaysStats
        default:
            return title
        }
    }

    // MARK: - Insight Type

    var insightType: InsightType? {
        switch self {
        case .insightsLatestPostSummary:
            return .latestPostSummary
        case .insightsAllTime:
            return .allTimeStats
        case .insightsFollowerTotals:
            return .followersTotals
        case .insightsMostPopularTime:
            return .mostPopularTime
        case .insightsTagsAndCategories:
            return .tagsAndCategories
        case .insightsAnnualSiteStats:
            return .annualSiteStats
        case .insightsCommentsAuthors, .insightsCommentsPosts:
            return .comments
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            return .followers
        case .insightsTodaysStats:
            return .todaysStats
        case .insightsPostingActivity:
            return .postingActivity
        case .insightsPublicize:
            return .publicize
        default:
            return nil
        }
    }

    // MARK: - Image Size Accessor

    static let defaultImageSize = CGFloat(24)

    var imageSize: CGFloat {
        switch self {
        case .insightsPublicize, .periodReferrers:
            return ImageSizes.socialImage
        case .insightsCommentsAuthors,
             .insightsFollowersWordPress,
             .insightsFollowersEmail,
             .periodAuthors:
            return ImageSizes.userImage
        default:
            return ImageSizes.defaultImage
        }
    }

    // MARK: String Structs

    struct InsightsHeaders {
        static let latestPostSummary = NSLocalizedString("Latest Post Summary", comment: "Insights latest post summary header")
        static let allTimeStats = NSLocalizedString("All-Time", comment: "Insights 'All-Time' header")
        static let mostPopularTime = NSLocalizedString("Most Popular Time", comment: "Insights 'Most Popular Time' header")
        static let followerTotals = NSLocalizedString("Follower Totals", comment: "Insights 'Follower Totals' header")
        static let publicize = NSLocalizedString("Publicize", comment: "Insights 'Publicize' header")
        static let todaysStats = NSLocalizedString("Today", comment: "Insights 'Today' header")
        static let postingActivity = NSLocalizedString("Posting Activity", comment: "Insights 'Posting Activity' header")
        static let comments = NSLocalizedString("Comments", comment: "Insights 'Comments' header")
        static let followers = NSLocalizedString("Followers", comment: "Insights 'Followers' header")
        static let tagsAndCategories = NSLocalizedString("Tags and Categories", comment: "Insights 'Tags and Categories' header")
        static let annualSiteStats = NSLocalizedString("This Year", comment: "Insights 'This Year' header")
        static let addCard = NSLocalizedString("Add stats card", comment: "Label for action to add a new Insight.")
    }

    struct DetailsTitles {
        static let annualSiteStats = NSLocalizedString("Annual Site Stats", comment: "Insights 'This Year' details view header")
    }

    struct InsightManagementTitles {
        static let todaysStats = NSLocalizedString("Today's Stats", comment: "Insights Management 'Today's Stats' title")
    }

    struct PeriodHeaders {
        static let postsAndPages = NSLocalizedString("Posts and Pages", comment: "Period Stats 'Posts and Pages' header")
        static let referrers = NSLocalizedString("Referrers", comment: "Period Stats 'Referrers' header")
        static let clicks = NSLocalizedString("Clicks", comment: "Period Stats 'Clicks' header")
        static let authors = NSLocalizedString("Authors", comment: "Period Stats 'Authors' header")
        static let countries = NSLocalizedString("Countries", comment: "Period Stats 'Countries' header")
        static let searchTerms = NSLocalizedString("Search Terms", comment: "Period Stats 'Search Terms' header")
        static let published = NSLocalizedString("Published", comment: "Period Stats 'Published' header")
        static let videos = NSLocalizedString("Videos", comment: "Period Stats 'Videos' header")
        static let fileDownloads = NSLocalizedString("File Downloads", comment: "Period Stats 'File Downloads' header")
    }

    struct PostStatsHeaders {
        static let recentWeeks = NSLocalizedString("Recent Weeks", comment: "Post Stats recent weeks header.")
        static let monthsAndYears = NSLocalizedString("Months and Years", comment: "Post Stats months and years header.")
        static let averageViewsPerDay = NSLocalizedString("Avg. Views Per Day", comment: "Post Stats average views per day header.")
    }

    struct ItemSubtitles {
        static let author = NSLocalizedString("Author", comment: "Label for list of stats by content author.")
        static let title = NSLocalizedString("Title", comment: "Label for list of stats by content title.")
        static let service = NSLocalizedString("Service", comment: "Label for connected service in Publicize stat.")
        static let follower = NSLocalizedString("Follower", comment: "Label for list of followers.")
        static let referrer = NSLocalizedString("Referrer", comment: "Label for link title in Referrers stat.")
        static let link = NSLocalizedString("Link", comment: "Label for link title in Clicks stat.")
        static let country = NSLocalizedString("Country", comment: "Label for list of countries.")
        static let searchTerm = NSLocalizedString("Search Term", comment: "Label for list of search term")
        static let period = NSLocalizedString("Period", comment: "Label for date periods.")
        static let file = NSLocalizedString("File", comment: "Label for list of file downloads.")
    }

    struct DataSubtitles {
        static let comments = NSLocalizedString("Comments", comment: "Label for number of comments.")
        static let views = NSLocalizedString("Views", comment: "Label for number of views.")
        static let followers = NSLocalizedString("Followers", comment: "Label for number of followers.")
        static let since = NSLocalizedString("Since", comment: "Label for time period in list of followers.")
        static let clicks = NSLocalizedString("Clicks", comment: "Label for number of clicks.")
        static let downloads = NSLocalizedString("Downloads", comment: "Label for number of file downloads.")
    }

    struct TabTitles {
        static let commentsAuthors = NSLocalizedString("Authors", comment: "Label for comments by author")
        static let commentsPosts = NSLocalizedString("Posts and Pages", comment: "Label for comments by posts and pages")
        static let followersWordPress = NSLocalizedString("WordPress.com", comment: "Label for WordPress.com followers")
        static let followersEmail = NSLocalizedString("Email", comment: "Label for email followers")
        static let overviewViews = NSLocalizedString("Views", comment: "Label for Period Overview views")
        static let overviewVisitors = NSLocalizedString("Visitors", comment: "Label for Period Overview visitors")
        static let overviewLikes = NSLocalizedString("Likes", comment: "Label for Period Overview likes")
        static let overviewComments = NSLocalizedString("Comments", comment: "Label for Period Overview comments")
    }

    struct TotalFollowers {
        static let wordPress = NSLocalizedString("Total WordPress.com Followers: %@", comment: "Label displaying total number of WordPress.com followers. %@ is the total.")
        static let email = NSLocalizedString("Total Email Followers: %@", comment: "Label displaying total number of Email followers. %@ is the total.")
    }

    static let noPostTitle = NSLocalizedString("(No Title)", comment: "Empty Post Title")

    // MARK: - Image Sizes

    struct ImageSizes {
        static let defaultImage = StatSection.defaultImageSize
        static let socialImage = CGFloat(20)
        static let userImage = CGFloat(28)
    }

}

// MARK: - Strings specific to Annual Site Stats

struct AnnualSiteStats {
    static let year = NSLocalizedString("Year", comment: "'This Year' label for the the year.")
    static let totalPosts = NSLocalizedString("Total Posts", comment: "'This Year' label for the total number of posts.")
    static let totalComments = NSLocalizedString("Total Comments", comment: "'This Year' label for total number of comments.")
    static let totalLikes = NSLocalizedString("Total Likes", comment: "'This Year' label for total number of likes.")
    static let totalWords = NSLocalizedString("Total Words", comment: "'This Year' label for total number of words.")
    static let commentsPerPost = NSLocalizedString("Avg Comments / Post", comment: "'This Year' label for average comments per post.")
    static let likesPerPost = NSLocalizedString("Avg Likes / Post", comment: "'This Year' label for average likes per post.")
    static let wordsPerPost = NSLocalizedString("Avg Words / Post", comment: "'This Year' label for average words per post.")
}
