@objc enum StatSection: Int {
    case periodOverview
    case periodPostsAndPages
    case periodReferrers
    case periodClicks
    case periodAuthors
    case periodCountries
    case periodSearchTerms
    case periodPublished
    case periodVideos
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
    case postDetailsGraph
    case postDetailsMonthsYears
    case postDetailsAveragePerDay
    case postDetailsRecentWeeks

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

    static let allPeriods = [StatSection.periodOverview,
                             .periodPostsAndPages,
                             .periodReferrers,
                             .periodClicks,
                             .periodAuthors,
                             .periodCountries,
                             .periodSearchTerms,
                             .periodPublished,
                             .periodVideos
    ]

    static let tabbedSectionComments = [StatSection.insightsCommentsAuthors, .insightsCommentsPosts]
    static let tabbedSectionFollowers = [StatSection.insightsFollowersWordPress, .insightsFollowersEmail]
    static let tabbedSections = StatSection.tabbedSectionComments + StatSection.tabbedSectionFollowers

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
             .periodVideos:
            return DataSubtitles.views
        case .insightsPublicize:
            return DataSubtitles.followers
        case .insightsFollowersWordPress,
             .insightsFollowersEmail:
            return DataSubtitles.since
        case .periodClicks:
            return DataSubtitles.clicks
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

    // MARK: String Structs

    struct InsightsHeaders {
        static let latestPostSummary = NSLocalizedString("Latest Post Summary", comment: "Insights latest post summary header")
        static let allTimeStats = NSLocalizedString("All Time Stats", comment: "Insights 'All Time Stats' header")
        static let mostPopularTime = NSLocalizedString("Most Popular Time", comment: "Insights 'Most Popular Time' header")
        static let followerTotals = NSLocalizedString("Follower Totals", comment: "Insights 'Follower Totals' header")
        static let publicize = NSLocalizedString("Publicize", comment: "Insights 'Publicize' header")
        static let todaysStats = NSLocalizedString("Today's Stats", comment: "Insights 'Today's Stats' header")
        static let postingActivity = NSLocalizedString("Posting Activity", comment: "Insights 'Posting Activity' header")
        static let comments = NSLocalizedString("Comments", comment: "Insights 'Comments' header")
        static let followers = NSLocalizedString("Followers", comment: "Insights 'Followers' header")
        static let tagsAndCategories = NSLocalizedString("Tags and Categories", comment: "Insights 'Tags and Categories' header")
        static let annualSiteStats = NSLocalizedString("Annual Site Stats", comment: "Insights 'Annual Site Stats' header")
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
    }

    struct DataSubtitles {
        static let comments = NSLocalizedString("Comments", comment: "Label for number of comments.")
        static let views = NSLocalizedString("Views", comment: "Label for number of views.")
        static let followers = NSLocalizedString("Followers", comment: "Label for number of followers.")
        static let since = NSLocalizedString("Since", comment: "Label for time period in list of followers.")
        static let clicks = NSLocalizedString("Clicks", comment: "Label for number of clicks.")
    }

    struct TabTitles {
        static let commentsAuthors = NSLocalizedString("Authors", comment: "Label for comments by author")
        static let commentsPosts = NSLocalizedString("Posts and Pages", comment: "Label for comments by posts and pages")
        static let followersWordPress = NSLocalizedString("WordPress.com", comment: "Label for WordPress.com followers")
        static let followersEmail = NSLocalizedString("Email", comment: "Label for email followers")
    }

    struct TotalFollowers {
        static let wordPress = NSLocalizedString("Total WordPress.com Followers: %@", comment: "Label displaying total number of WordPress.com followers. %@ is the total.")
        static let email = NSLocalizedString("Total Email Followers: %@", comment: "Label displaying total number of Email followers. %@ is the total.")
    }

}
