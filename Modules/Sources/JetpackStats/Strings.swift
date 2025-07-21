import Foundation
import WordPressShared

enum Strings {
    static let stats = AppLocalizedString("jetpackStats.title", value: "Stats", comment: "Stats screen title")

    enum Tabs {
        static let traffic = AppLocalizedString("jetpackStats.tabs.traffic", value: "Traffic", comment: "Traffic tab")
        static let realtime = AppLocalizedString("jetpackStats.tabs.realtime", value: "Realtime", comment: "Realtime tab")
        static let insights = AppLocalizedString("jetpackStats.tabs.insights", value: "Insights", comment: "Insights tab")
        static let subscribers = AppLocalizedString("jetpackStats.tabs.subscribers", value: "Subscribers", comment: "Subscribers tab")
    }

    enum Calendar {
        static let yesterday = AppLocalizedString("jetpackStats.calendar.yesterday", value: "Yesterday", comment: "Yesterday date range")
        static let today = AppLocalizedString("jetpackStats.calendar.today", value: "Today", comment: "Today date range")
        static let thisWeek = AppLocalizedString("jetpackStats.calendar.thisWeek", value: "This Week", comment: "This week date range")
        static let thisMonth = AppLocalizedString("jetpackStats.calendar.thisMonth", value: "This Month", comment: "This month date range")
        static let thisQuarter = AppLocalizedString("jetpackStats.calendar.thisQuarter", value: "This Quarter", comment: "This quarter date range")
        static let thisYear = AppLocalizedString("jetpackStats.calendar.thisYear", value: "This Year", comment: "This year date range")
        static let last7Days = AppLocalizedString("jetpackStats.calendar.last7Days", value: "Last 7 Days", comment: "Last 7 days date range")
        static let last28Days = AppLocalizedString("jetpackStats.calendar.last28Days", value: "Last 28 Days", comment: "Last 28 days date range")
        static let last30Days = AppLocalizedString("jetpackStats.calendar.last30Days", value: "Last 30 Days", comment: "Last 30 days date range")
        static let last90Days = AppLocalizedString("jetpackStats.calendar.last90Days", value: "Last 90 Days", comment: "Last 90 days date range")
        static let last6Months = AppLocalizedString("jetpackStats.calendar.last6Months", value: "Last 6 Months", comment: "Last 6 months date range")
        static let last12Months = AppLocalizedString("jetpackStats.calendar.last12Months", value: "Last 12 Months", comment: "Last 12 months date range")
        static let last5Years = AppLocalizedString("jetpackStats.calendar.last5Years", value: "Last 5 Years", comment: "Last 5 years date range")
        static let last10Years = AppLocalizedString("jetpackStats.calendar.last10Years", value: "Last 10 Years", comment: "Last 10 years date range")
        static let week = AppLocalizedString("jetpackStats.calendar.week", value: "Week", comment: "Week time period")
        static let month = AppLocalizedString("jetpackStats.calendar.month", value: "Month", comment: "Month time period")
        static let quarter = AppLocalizedString("jetpackStats.calendar.quarter", value: "Quarter", comment: "Quarter time period")
        static let year = AppLocalizedString("jetpackStats.calendar.year", value: "Year", comment: "Year time period")
    }

    enum SiteMetrics {
        static let views = AppLocalizedString("jetpackStats.siteMetrics.views", value: "Views", comment: "Site views metric")
        static let visitors = AppLocalizedString("jetpackStats.siteMetrics.visitors", value: "Visitors", comment: "Site visitors metric")
        static let visitorsNow = AppLocalizedString("jetpackStats.siteMetrics.visitorsNow", value: "Visitors Now", comment: "Current active visitors metric")
        static let likes = AppLocalizedString("jetpackStats.siteMetrics.likes", value: "Likes", comment: "Site likes metric")
        static let comments = AppLocalizedString("jetpackStats.siteMetrics.comments", value: "Comments", comment: "Site comments metric")
        static let posts = AppLocalizedString("jetpackStats.siteMetrics.posts", value: "Posts", comment: "Site posts metric")
        static let timeOnSite = AppLocalizedString("jetpackStats.siteMetrics.timeOnSite", value: "Time on Site", comment: "Time on site metric")
        static let bounceRate = AppLocalizedString("jetpackStats.siteMetrics.bounceRate", value: "Bounce Rate", comment: "Bounce rate metric")
        static let downloads = AppLocalizedString("jetpackStats.siteMetrics.downloads", value: "Downloads", comment: "Download count")
    }

    enum SiteDataTypes {
        static let postsAndPages = AppLocalizedString("jetpackStats.siteDataTypes.postsAndPages", value: "Posts & Pages", comment: "Posts and pages data type")
        static let posts = AppLocalizedString("jetpackStats.siteDataTypes.posts", value: "Posts", comment: "Posts data type")
        static let pages = AppLocalizedString("jetpackStats.siteDataTypes.pages", value: "Pages", comment: "Pages data type")
        static let authors = AppLocalizedString("jetpackStats.siteDataTypes.authors", value: "Authors", comment: "Authors data type")
        static let referrers = AppLocalizedString("jetpackStats.siteDataTypes.referrers", value: "Referrers", comment: "Referrers data type")
        static let locations = AppLocalizedString("jetpackStats.siteDataTypes.locations", value: "Locations", comment: "Locations data type")
        static let externalLinks = AppLocalizedString("jetpackStats.siteDataTypes.externalLinks", value: "External Links", comment: "External links data type")
        static let fileDownloads = AppLocalizedString("jetpackStats.siteDataTypes.fileDownloads", value: "File Downloads", comment: "File downloads data type")
        static let searchTerms = AppLocalizedString("jetpackStats.siteDataTypes.searchTerms", value: "Search Terms", comment: "Search terms data type")
        static let videos = AppLocalizedString("jetpackStats.siteDataTypes.videos", value: "Videos", comment: "Videos data type")
    }

    enum Buttons {
        static let cancel = AppLocalizedString("jetpackStats.button.cancel", value: "Cancel", comment: "Cancel button")
        static let apply = AppLocalizedString("jetpackStats.button.apply", value: "Apply", comment: "Apply button")
        static let share = AppLocalizedString("jetpackStats.button.share", value: "Share", comment: "Share chart menu item")
        static let showAll = AppLocalizedString("jetpackStats.button.showAll", value: "Show All", comment: "Button title")
    }

    enum DatePicker {
        static let customRange = AppLocalizedString("jetpackStats.datePicker.customRange", value: "Custom Range", comment: "Title for custom date range picker")
        static let customRangeMenu = AppLocalizedString("jetpackStats.datePicker.customRangeMenu", value: "Custom Range…", comment: "Menu item for custom date range picker")
        static let morePeriods = AppLocalizedString("jetpackStats.datePicker.morePeriods", value: "More Periods…", comment: "Menu item for more date period options")
        static let from = AppLocalizedString("jetpackStats.datePicker.from", value: "From", comment: "From date label")
        static let to = AppLocalizedString("jetpackStats.datePicker.to", value: "To", comment: "To date label")
        static let quickPeriodsForStartDate = AppLocalizedString("jetpackStats.datePicker.quickPeriodsForStartDate", value: "Quick periods for start date", comment: "Label for quick period selection")
        static let siteTimeZone = AppLocalizedString("jetpackStats.datePicker.siteTimeZone", value: "Site Time Zone", comment: "Site time zone header")
        static let siteTimeZoneDescription = AppLocalizedString("jetpackStats.datePicker.siteTimeZoneDescription", value: "Stats are reported and shown in your site's time zone. If a visitor comes to your site on Tuesday in their time zone, but it's Monday in your site time zone, the visit is recorded as Monday.", comment: "Explanation of how stats are reported in site time zone")
        static let compareWith = AppLocalizedString("jetpackStats.datePicker.compareWith", value: "Compare With…", comment: "Title for comparison menu")
        static let precedingPeriod = AppLocalizedString("jetpackStats.datePicker.precedingPeriod", value: "Preceding Period", comment: "Compare with preceding period option")
        static let samePeriodLastYear = AppLocalizedString("jetpackStats.datePicker.lastYear", value: "Last Year", comment: "Compare with same period last year option")
    }

    enum Chart {
        static let showData = AppLocalizedString("jetpackStats.chart.showData", value: "Show Data", comment: "Show chart data menu item")
        static let lineChart = AppLocalizedString("jetpackStats.chart.lineChart", value: "Lines", comment: "Line chart type")
        static let barChart = AppLocalizedString("jetpackStats.chart.barChart", value: "Bars", comment: "Bar chart type")
        static let incompleteData = AppLocalizedString("jetpackStats.chart.incompleteData", value: "Might show incomplete data", comment: "Shown when current period data might be incomplete")
        static let hourlyDataUnavailable = AppLocalizedString("jetpackStats.chart.hourlyDataNotAvailable", value: "Hourly data not available", comment: "Shown for metrics that don't support hourly data")
        static let empty = AppLocalizedString("jetpackStats.chart.dataEmpty", value: "Not data available", comment: "Shown for empty states")
    }

    enum TopListTitles {
        static let mostViewed = AppLocalizedString("jetpackStats.topList.mostViewed", value: "Most Viewed", comment: "Title for most viewed items")
        static let mostVisitors = AppLocalizedString("jetpackStats.topList.mostVisitors", value: "Most Visitors", comment: "Title for items with most visitors")
        static let mostCommented = AppLocalizedString("jetpackStats.topList.mostCommented", value: "Most Commented", comment: "Title for most commented items")
        static let mostLiked = AppLocalizedString("jetpackStats.topList.mostLiked", value: "Most Liked", comment: "Title for most liked items")
        static let mostPosts = AppLocalizedString("jetpackStats.topList.mostPosts", value: "Most Posts", comment: "Title for most posts (per author)")
        static let highestBounceRate = AppLocalizedString("jetpackStats.topList.highestBounceRate", value: "Highest Bounce Rate", comment: "Title for items with highest bounce rate")
        static let longestTimeOnSite = AppLocalizedString("jetpackStats.topList.longestTimeOnSite", value: "Longest Time on Site", comment: "Title for items with longest time on site")
        static let mostDownloadeded = AppLocalizedString("jetpackStats.topList.mostDownloads", value: "Most Downloaded", comment: "Title for chart")
    }

    enum Errors {
        static let generic = AppLocalizedString("jetpackStats.chart.generitcError", value: "Something went wrong", comment: "Genertic error message")
    }

    enum SearchTerms {
        static let fromSearch = AppLocalizedString("jetpackStats.searchTerms.fromSearch", value: "From search", comment: "Caption shown below search terms")
    }

    enum Videos {
        static func postId(_ id: String) -> String {
            String.localizedStringWithFormat(
                AppLocalizedString("jetpackStats.videos.postId", value: "Post #%1$@", comment: "Post ID for video. %1$@ is the post ID"),
                id
            )
        }
    }
}
