enum StatSection: Int {
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
        default:
            return ""
        }
    }

    var itemSubtitle: String {
        switch self {
        case .insightsCommentsPosts, .insightsTagsAndCategories:
            return ItemSubtitles.title
        case .insightsCommentsAuthors:
            return ItemSubtitles.author
        case .insightsPublicize:
            return ItemSubtitles.service
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            return ItemSubtitles.follower
        default:
            return ""
        }
    }

    var dataSubtitle: String {
        switch self {
        case .insightsCommentsAuthors, .insightsCommentsPosts:
            return DataSubtitles.comments
        case .insightsTagsAndCategories:
            return DataSubtitles.views
        case .insightsPublicize:
            return DataSubtitles.followers
        case .insightsFollowersWordPress, .insightsFollowersEmail:
            return DataSubtitles.since
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

    struct ItemSubtitles {
        static let author = NSLocalizedString("Author", comment: "Author label for list of commenters.")
        static let title = NSLocalizedString("Title", comment: "Title label for list of posts.")
        static let service = NSLocalizedString("Service", comment: "Publicize label for connected service")
        static let follower = NSLocalizedString("Follower", comment: "Followers label for list of followers.")
    }

    struct DataSubtitles {
        static let comments = NSLocalizedString("Comments", comment: "Label for comment count, either by author or post.")
        static let views = NSLocalizedString("Views", comment: "'Tags and Categories' label for tag/category number of views.")
        static let followers = NSLocalizedString("Followers", comment: "Publicize label for number of followers")
        static let since = NSLocalizedString("Since", comment: "Followers label for time period in list of follower.")
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
