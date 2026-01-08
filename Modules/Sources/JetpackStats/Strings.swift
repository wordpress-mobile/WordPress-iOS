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
        static let today = AppLocalizedString("jetpackStats.calendar.today", value: "Today", comment: "Today date range")
        static let thisWeek = AppLocalizedString("jetpackStats.calendar.thisWeek", value: "This Week", comment: "This week date range")
        static let thisMonth = AppLocalizedString("jetpackStats.calendar.thisMonth", value: "This Month", comment: "This month date range")
        static let thisQuarter = AppLocalizedString("jetpackStats.calendar.thisQuarter", value: "This Quarter", comment: "This quarter date range")
        static let thisYear = AppLocalizedString("jetpackStats.calendar.thisYear", value: "This Year", comment: "This year date range")
        static let last7Days = AppLocalizedString("jetpackStats.calendar.last7Days", value: "Last 7 Days", comment: "Last 7 days date range")
        static let last28Days = AppLocalizedString("jetpackStats.calendar.last28Days", value: "Last 28 Days", comment: "Last 28 days date range")
        static let last30Days = AppLocalizedString("jetpackStats.calendar.last30Days", value: "Last 30 Days", comment: "Last 30 days date range")
        static let last12Weeks = AppLocalizedString("jetpackStats.calendar.last12Weeks", value: "Last 12 Weeks", comment: "Last 12 weeks (84 days) date range")
        static let last6Months = AppLocalizedString("jetpackStats.calendar.last6Months", value: "Last 6 Months", comment: "Last 6 months date range")
        static let last12Months = AppLocalizedString("jetpackStats.calendar.last12Months", value: "Last 12 Months", comment: "Last 12 months date range")
        static let last3Years = AppLocalizedString("jetpackStats.calendar.last3Years", value: "Last 3 Years", comment: "Last 3 years date range")
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
        static let archive = AppLocalizedString("jetpackStats.siteDataTypes.archive", value: "Archive", comment: "Archive data type")
        static let authors = AppLocalizedString("jetpackStats.siteDataTypes.authors", value: "Authors", comment: "Authors data type")
        static let referrers = AppLocalizedString("jetpackStats.siteDataTypes.referrers", value: "Referrers", comment: "Referrers data type")
        static let locations = AppLocalizedString("jetpackStats.siteDataTypes.locations", value: "Locations", comment: "Locations data type")
        static let clicks = AppLocalizedString("jetpackStats.siteDataTypes.clicks", value: "Clicks", comment: "Clicks data type (external links)")
        static let fileDownloads = AppLocalizedString("jetpackStats.siteDataTypes.fileDownloads", value: "File Downloads", comment: "File downloads data type")
        static let searchTerms = AppLocalizedString("jetpackStats.siteDataTypes.searchTerms", value: "Search Terms", comment: "Search terms data type")
        static let videos = AppLocalizedString("jetpackStats.siteDataTypes.videos", value: "Videos", comment: "Videos data type")
    }

    enum Countries {
        static let noViews = AppLocalizedString(
            "jetpackStats.countries.noViews",
            value: "No views",
            comment: "Message shown when a country has no views"
        )
    }

    enum Buttons {
        static let cancel = AppLocalizedString("jetpackStats.button.cancel", value: "Cancel", comment: "Cancel button")
        static let apply = AppLocalizedString("jetpackStats.button.apply", value: "Apply", comment: "Apply button")
        static let done = AppLocalizedString("jetpackStats.button.done", value: "Done", comment: "Done button")
        static let share = AppLocalizedString("jetpackStats.button.share", value: "Share", comment: "Share chart menu item")
        static let showAll = AppLocalizedString("jetpackStats.button.showAll", value: "Show All", comment: "Button title")
        static let showMore = AppLocalizedString("jetpackStats.button.showMore", value: "Show More", comment: "Button to expand and show more items")
        static let showLess = AppLocalizedString("jetpackStats.button.showLess", value: "Show Less", comment: "Button to collapse and show fewer items")
        static let ok = AppLocalizedString("jetpackStats.button.ok", value: "OK", comment: "OK button")
        static let downloadCSV = AppLocalizedString("jetpackStats.button.downloadCSV", value: "Download CSV", comment: "Button to download data as CSV file")
        static let learnMore = AppLocalizedString("jetpackStats.button.learnMore", value: "Learn More", comment: "Learn more about stats button")
        static let addCard = AppLocalizedString("jetpackStats.button.addCard", value: "Add Card", comment: "Button to add a new chart")
        static let deleteWidget = AppLocalizedString("jetpackStats.button.deleteWidget", value: "Delete Card", comment: "Button to delete a chart or widget")
        static let customize = AppLocalizedString("jetpackStats.button.customize", value: "Edit Card", comment: "Button to customize a chart or widget")
        static let resetSettings = AppLocalizedString("jetpackStats.button.resetSettings", value: "Reset Settings", comment: "Button to reset chart settings to default")
        static let moveCard = AppLocalizedString("jetpackStats.button.moveCard", value: "Move Card", comment: "Button to move a card")
        static let moveUp = AppLocalizedString("jetpackStats.button.moveUp", value: "Move Up", comment: "Button to move card up")
        static let moveDown = AppLocalizedString("jetpackStats.button.moveDown", value: "Move Down", comment: "Button to move card down")
        static let moveToTop = AppLocalizedString("jetpackStats.button.moveToTop", value: "Move to Top", comment: "Button to move card to the top")
        static let moveToBottom = AppLocalizedString("jetpackStats.button.moveToBottom", value: "Move to Bottom", comment: "Button to move card to the bottom")
    }

    enum DatePicker {
        static let customRange = AppLocalizedString("jetpackStats.datePicker.customRange", value: "Custom Range", comment: "Title for custom date range picker")
        static let customRangeMenu = AppLocalizedString("jetpackStats.datePicker.customRangeMenu", value: "Custom Range…", comment: "Menu item for custom date range picker")
        static let morePeriods = AppLocalizedString("jetpackStats.datePicker.more", value: "More…", comment: "Menu item for more date period options")
        static let from = AppLocalizedString("jetpackStats.datePicker.from", value: "From", comment: "From date label")
        static let to = AppLocalizedString("jetpackStats.datePicker.to", value: "To", comment: "To date label")
        static let quickPeriodsForStartDate = AppLocalizedString("jetpackStats.datePicker.quickPeriodsForStartDate", value: "Quick periods for start date", comment: "Label for quick period selection")
        static let siteTimeZone = AppLocalizedString("jetpackStats.datePicker.siteTimeZone", value: "Site Time Zone", comment: "Site time zone header")
        static let siteTimeZoneDescription = AppLocalizedString("jetpackStats.datePicker.siteTimeZoneDescription", value: "Stats are reported and shown in your site's time zone. If a visitor comes to your site on Tuesday in their time zone, but it's Monday in your site time zone, the visit is recorded as Monday.", comment: "Explanation of how stats are reported in site time zone")
        static let compareWith = AppLocalizedString("jetpackStats.datePicker.compareWith", value: "Compare With…", comment: "Title for comparison menu")
        static let precedingPeriod = AppLocalizedString("jetpackStats.datePicker.precedingPeriod", value: "Preceding Period", comment: "Compare with preceding period option")
        static let samePeriodLastYear = AppLocalizedString("jetpackStats.datePicker.lastYear", value: "Last Year", comment: "Compare with same period last year option")
    }

    enum DateRangeTips {
        static let title = AppLocalizedString("jetpackStats.dateRangeTip.title", value: "Navigate Through Time", comment: "Title for stats date range control tip")
        static let message = AppLocalizedString("jetpackStats.dateRangeTip.message", value: "View recent days, weeks, months, years, or select custom date ranges.", comment: "Message explaining how to use the date range control")
    }

    enum Chart {
        static let showData = AppLocalizedString("jetpackStats.chart.showData", value: "Show Data", comment: "Show chart data menu item")
        static let lineChart = AppLocalizedString("jetpackStats.chart.lineChart", value: "Lines", comment: "Line chart type")
        static let barChart = AppLocalizedString("jetpackStats.chart.barChart", value: "Bars", comment: "Bar chart type")
        static let incompleteData = AppLocalizedString("jetpackStats.chart.incompleteData", value: "Might show incomplete data", comment: "Shown when current period data might be incomplete")
        static let hourlyDataUnavailable = AppLocalizedString("jetpackStats.chart.hourlyDataNotAvailable", value: "Hourly data not available", comment: "Shown for metrics that don't support hourly data")
        static let empty = AppLocalizedString("jetpackStats.chart.dataEmpty", value: "No data for period", comment: "Shown for empty states")
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
        static let top10 = AppLocalizedString("jetpackStats.postDetails.top10", value: "Top 10", comment: "Section title")
        static let top50 = AppLocalizedString("jetpackStats.postDetails.top50", value: "Top 50", comment: "Section title")
    }

    enum Errors {
        static let generic = AppLocalizedString("jetpackStats.chart.generitcError", value: "Something went wrong", comment: "Genertic error message")
    }

    enum ArchiveSections {
        static func itemCount(_ count: Int) -> String {
            let format = count == 1
                ? AppLocalizedString("jetpackStats.archiveSections.itemCount.singular", value: "%1$d item", comment: "Singular item count for archive sections. %1$d is the number.")
                : AppLocalizedString("jetpackStats.archiveSections.itemCount.plural", value: "%1$d items", comment: "Plural item count for archive sections. %1$d is the number.")
            return String.localizedStringWithFormat(format, count)
        }
    }

    enum PostDetails {
        static let title = AppLocalizedString("jetpackStats.postDetails.title", value: "Post Stats", comment: "Navigation title")
        static func published(_ date: String) -> String {
            String.localizedStringWithFormat(
                AppLocalizedString("jetpackStats.postDetails.published", value: "Published %1$@", comment: "Shows when the post was published. %1$@ is the formatted date."),
                date
            )
        }

        // Weekly Activity
        static let recentWeeks = AppLocalizedString("jetpackStats.postDetails.recentWeeks", value: "Recent Weeks", comment: "Title for recent weeks activity heatmap")
        static let weeklyActivity = AppLocalizedString("jetpackStats.postDetails.weeklyActivity", value: "Weekly Activity", comment: "Title for weekly activity heatmap")

        // Email Metrics
        static let emailMetrics = AppLocalizedString("jetpackStats.postDetails.emailMetrics", value: "Emails", comment: "Title for email metrics card")
        static let emailsSent = AppLocalizedString("jetpackStats.postDetails.emailsSent", value: "Emails Sent", comment: "Must be short!Label for emails sent metric")
        static let uniqueOpens = AppLocalizedString("jetpackStats.postDetails.uniqueOpens", value: "Unique Opens", comment: "Must be short!Label for unique email opens metric")
        static let totalOpens = AppLocalizedString("jetpackStats.postDetails.totalOpens", value: "Total Opens", comment: "Must be short!Label for total email opens metric")
        static let openRate = AppLocalizedString("jetpackStats.postDetails.openRate", value: "Open Rate", comment: "Must be short! Label for email open rate metric")
        static let less = AppLocalizedString("jetpackStats.postDetails.less", value: "Less", comment: "Legend label for lower activity")
        static let more = AppLocalizedString("jetpackStats.postDetails.more", value: "More", comment: "Legend label for higher activity")

        // Monthly Activity
        static let monthlyActivity = AppLocalizedString("jetpackStats.postDetails.monthsAndYears", value: "Recent Months", comment: "Title for monthly activity heatmap")

        // Likes
        static let noLikesYet = AppLocalizedString("jetpackStats.postDetails.noLikesYet", value: "No likes yet", comment: "Label")
        static func likesCount(_ count: Int) -> String {
            let format = count == 1
                ? AppLocalizedString("jetpackStats.postDetails.like", value: "%1$d like", comment: "Singular like count. %1$d is the number.")
                : AppLocalizedString("jetpackStats.postDetails.likes", value: "%1$d likes", comment: "Plural likes count. %1$d is the number.")
            return String.localizedStringWithFormat(format, count)
        }

        // Tooltip
        static let weekTotal = AppLocalizedString("jetpackStats.postDetails.weekTotal", value: "Week Total", comment: "Label for weekly total in tooltip")
        static let dailyAverage = AppLocalizedString("jetpackStats.postDetails.dailyAverage", value: "Daily Average", comment: "Label for daily average in tooltip")
        static let weekOverWeek = AppLocalizedString("jetpackStats.postDetails.weekOverWeek", value: "Week over Week", comment: "Label for week-over-week comparison in tooltip")
    }

    enum AuthorDetails {
        static let title = AppLocalizedString("jetpackStats.authorDetails.title", value: "Author", comment: "Title for the author details screen")
    }

    enum ReferrerDetails {
        static let title = AppLocalizedString("jetpackStats.referrerDetails.title", value: "Referrer", comment: "Title for the referrer details screen")
        static let markAsSpam = AppLocalizedString("jetpackStats.referrerDetails.markAsSpam", value: "Mark as Spam", comment: "Button to mark a referrer as spam")
        static let markedAsSpam = AppLocalizedString("jetpackStats.referrerDetails.markedAsSpam", value: "Marked as Spam", comment: "Label shown when a referrer is already marked as spam")
        static let referralSources = AppLocalizedString("jetpackStats.referrerDetails.referralSources", value: "Referral Sources", comment: "Section title for the list of referral sources")
        static let markAsSpamError = AppLocalizedString("jetpackStats.referrerDetails.markAsSpamError", value: "Failed to mark as spam", comment: "Error message when marking a referrer as spam fails")
        static let errorAlertTitle = AppLocalizedString("jetpackStats.referrerDetails.errorAlertTitle", value: "Error", comment: "Title for error alert when marking referrer as spam fails")
    }

    enum ExternalLinkDetails {
        static let title = AppLocalizedString("jetpackStats.externalLinkDetails.title", value: "External Link", comment: "Title for the external link details screen")
        static let openLink = AppLocalizedString("jetpackStats.externalLinkDetails.openLink", value: "Open Link", comment: "Button to open the external link in browser")
        static let childLinks = AppLocalizedString("jetpackStats.externalLinkDetails.childLinks", value: "Sub-links", comment: "Section title for the list of child links")
    }

    enum ContextMenuActions {
        static let openInBrowser = AppLocalizedString("jetpackStats.contextMenu.openInBrowser", value: "Open in Browser", comment: "Context menu action to open link in browser")
        static let copyURL = AppLocalizedString("jetpackStats.contextMenu.copyURL", value: "Copy URL", comment: "Context menu action to copy URL")
        static let copyTitle = AppLocalizedString("jetpackStats.contextMenu.copyTitle", value: "Copy Title", comment: "Context menu action to copy title")
        static let copyName = AppLocalizedString("jetpackStats.contextMenu.copyName", value: "Copy Name", comment: "Context menu action to copy name")
        static let copyDomain = AppLocalizedString("jetpackStats.contextMenu.copyDomain", value: "Copy Domain", comment: "Context menu action to copy domain")
        static let copyCountryName = AppLocalizedString("jetpackStats.contextMenu.copyCountryName", value: "Copy Country Name", comment: "Context menu action to copy country name")
        static let copyFileName = AppLocalizedString("jetpackStats.contextMenu.copyFileName", value: "Copy File Name", comment: "Context menu action to copy file name")
        static let copyFilePath = AppLocalizedString("jetpackStats.contextMenu.copyFilePath", value: "Copy File Path", comment: "Context menu action to copy file path")
        static let searchInGoogle = AppLocalizedString("jetpackStats.contextMenu.searchInGoogle", value: "Search in Google", comment: "Context menu action to search term in Google")
        static let copySearchTerm = AppLocalizedString("jetpackStats.contextMenu.copySearchTerm", value: "Copy Search Term", comment: "Context menu action to copy search term")
        static let copyVideoURL = AppLocalizedString("jetpackStats.contextMenu.copyVideoURL", value: "Copy Video URL", comment: "Context menu action to copy video URL")
    }

    enum CSVExport {
        static let title = AppLocalizedString("jetpackStats.csv.title", value: "Title", comment: "CSV header for title column")
        static let url = AppLocalizedString("jetpackStats.csv.url", value: "URL", comment: "CSV header for URL column")
        static let date = AppLocalizedString("jetpackStats.csv.date", value: "Date", comment: "CSV header for date column")
        static let type = AppLocalizedString("jetpackStats.csv.type", value: "Type", comment: "CSV header for type column")
        static let name = AppLocalizedString("jetpackStats.csv.name", value: "Name", comment: "CSV header for name column")
        static let domain = AppLocalizedString("jetpackStats.csv.domain", value: "Domain", comment: "CSV header for domain column")
        static let country = AppLocalizedString("jetpackStats.csv.country", value: "Country", comment: "CSV header for country column")
        static let countryCode = AppLocalizedString("jetpackStats.csv.countryCode", value: "Country Code", comment: "CSV header for country code column")
        static let role = AppLocalizedString("jetpackStats.csv.role", value: "Role", comment: "CSV header for role column")
        static let fileName = AppLocalizedString("jetpackStats.csv.fileName", value: "File Name", comment: "CSV header for file name column")
        static let filePath = AppLocalizedString("jetpackStats.csv.filePath", value: "File Path", comment: "CSV header for file path column")
        static let searchTerm = AppLocalizedString("jetpackStats.csv.searchTerm", value: "Search Term", comment: "CSV header for search term column")
        static let videoURL = AppLocalizedString("jetpackStats.csv.videoURL", value: "Video URL", comment: "CSV header for video URL column")
        static let section = AppLocalizedString("jetpackStats.csv.section", value: "Section", comment: "CSV header for section column")
    }

    enum Cards {
        static let chart = AppLocalizedString("jetpackStats.addChart.chartOption", value: "Chart", comment: "Chart option title")
        static let chartDescription = AppLocalizedString("jetpackStats.addChart.chartDescription", value: "Visualize trends over time", comment: "Chart option description")
        static let topList = AppLocalizedString("jetpackStats.addChart.topListOption", value: "Top List", comment: "Top list option title")
        static let topListDescription = AppLocalizedString("jetpackStats.addChart.topListDescription", value: "See your top performing content", comment: "Top list option description")
        static let today = AppLocalizedString("jetpackStats.addChart.today", value: "Today", comment: "Today chart title")
        static let todayDescription = AppLocalizedString("jetpackStats.addChart.topListDescription", value: "See today's metrics", comment: "Today option description")
        static let selectMetric = AppLocalizedString("jetpackStats.addChart.selectMetric", value: "Select Metrics", comment: "Title for metric selection")
        static let selectDataType = AppLocalizedString("jetpackStats.addChart.selectDataType", value: "Select Data Type", comment: "Title for data type selection")
    }

    enum Today {
        static let title = AppLocalizedString("jetpackStats.todayCard.title", value: "Today", comment: "Today card title")
    }

    enum Accessibility {
        // Tab Bar
        static let statsTabBar = AppLocalizedString("jetpackStats.accessibility.statsTabBar", value: "Stats navigation tabs", comment: "Accessibility label for stats tab bar")
        static func tabSelected(_ tabName: String) -> String {
            String.localizedStringWithFormat(
                AppLocalizedString("jetpackStats.accessibility.tabSelected", value: "%1$@ tab selected", comment: "Accessibility announcement when a tab is selected. %1$@ is the tab name."),
                tabName
            )
        }
        static func selectTab(_ tabName: String) -> String {
            String.localizedStringWithFormat(
                AppLocalizedString("jetpackStats.accessibility.selectTab", value: "Select %1$@ tab", comment: "Accessibility hint for tab selection. %1$@ is the tab name."),
                tabName
            )
        }

        // Charts
        static let chartContainer = AppLocalizedString("jetpackStats.accessibility.chartContainer", value: "Stats chart", comment: "Accessibility label for chart container")
        static func chartValue(metric: String, value: String, date: String) -> String {
            String.localizedStringWithFormat(
                AppLocalizedString("jetpackStats.accessibility.chartValue", value: "%1$@: %2$@ on %3$@", comment: "Chart data point accessibility label. %1$@ is metric name, %2$@ is value, %3$@ is date."),
                metric, value, date
            )
        }
        static func chartTrend(metric: String, trend: String) -> String {
            String.localizedStringWithFormat(
                AppLocalizedString("jetpackStats.accessibility.chartTrend", value: "%1$@ %2$@", comment: "Chart trend accessibility label. %1$@ is metric name, %2$@ is trend description."),
                metric, trend
            )
        }
        static let viewChartData = AppLocalizedString("jetpackStats.accessibility.viewChartData", value: "View detailed chart data", comment: "Accessibility hint for viewing chart data")

        // Top Lists
        static func topListItem(rank: Int, title: String, value: String) -> String {
            String.localizedStringWithFormat(
                AppLocalizedString("jetpackStats.accessibility.topListItem", value: "Rank %1$d: %2$@, %3$@", comment: "Top list item accessibility label. %1$d is rank, %2$@ is title, %3$@ is value."),
                rank, title, value
            )
        }
        static let viewMoreDetails = AppLocalizedString("jetpackStats.accessibility.viewMoreDetails", value: "Double tap to view more details", comment: "Accessibility hint for items that can show more details")

        // Date Range
        static func dateRangeSelected(_ range: String) -> String {
            String.localizedStringWithFormat(
                AppLocalizedString("jetpackStats.accessibility.dateRangeSelected", value: "Date range: %1$@", comment: "Selected date range accessibility label. %1$@ is the range."),
                range
            )
        }
        static let selectDateRange = AppLocalizedString("jetpackStats.accessibility.selectDateRange", value: "Select date range", comment: "Accessibility hint for date range selection")
        static let nextPeriod = AppLocalizedString("jetpackStats.accessibility.nextPeriod", value: "Next period", comment: "Accessibility label for next period navigation button")
        static let previousPeriod = AppLocalizedString("jetpackStats.accessibility.previousPeriod", value: "Previous period", comment: "Accessibility label for previous period navigation button")
        static let navigateToNextDateRange = AppLocalizedString("jetpackStats.accessibility.navigateToNextDateRange", value: "Navigate to next date range", comment: "Accessibility hint for next period navigation")
        static let navigateToPreviousDateRange = AppLocalizedString("jetpackStats.accessibility.navigateToPreviousDateRange", value: "Navigate to previous date range", comment: "Accessibility hint for previous period navigation")

        // Cards
        static let addCardButton = AppLocalizedString("jetpackStats.accessibility.addCardButton", value: "Add new stats card", comment: "Accessibility label for add card button")
        static func cardTitle(_ title: String) -> String {
            String.localizedStringWithFormat(
                AppLocalizedString("jetpackStats.accessibility.cardTitle", value: "%1$@ card", comment: "Card title accessibility label. %1$@ is the card title."),
                title
            )
        }

        // Loading States
        static let loadingStats = AppLocalizedString("jetpackStats.accessibility.loadingStats", value: "Loading statistics", comment: "Accessibility label for loading state")
        static let statsLoaded = AppLocalizedString("jetpackStats.accessibility.statsLoaded", value: "Statistics loaded", comment: "Accessibility announcement when stats finish loading")

        // Error States
        static let errorLoadingStats = AppLocalizedString("jetpackStats.accessibility.errorLoadingStats", value: "Error loading statistics", comment: "Accessibility label for error state")
        static let retryLoadingStats = AppLocalizedString("jetpackStats.accessibility.retryLoadingStats", value: "Double tap to retry loading statistics", comment: "Accessibility hint for retry action")

        // Navigation
        static let backToStats = AppLocalizedString("jetpackStats.accessibility.backToStats", value: "Back to stats", comment: "Accessibility label for back navigation")
        static let openInBrowser = AppLocalizedString("jetpackStats.accessibility.openInBrowser", value: "Open in browser", comment: "Accessibility label for opening link in browser")
        static let moreOptions = AppLocalizedString("jetpackStats.accessibility.moreOptions", value: "More options", comment: "Accessibility label for more options menu")

        // Empty States
        static let noDataAvailable = AppLocalizedString("jetpackStats.accessibility.noDataAvailable", value: "No data available for this period", comment: "Accessibility label for empty data state")

        // Realtime
        static let realtimeVisitorCount = AppLocalizedString("jetpackStats.accessibility.realtimeVisitorCount", value: "Current visitors online", comment: "Accessibility label for realtime visitor count")
        static func visitorsNow(_ count: Int) -> String {
            let format = count == 1
                ? AppLocalizedString("jetpackStats.accessibility.visitorNow", value: "%1$d visitor online now", comment: "Singular visitor count. %1$d is the number.")
                : AppLocalizedString("jetpackStats.accessibility.visitorsNow", value: "%1$d visitors online now", comment: "Plural visitors count. %1$d is the number.")
            return String.localizedStringWithFormat(format, count)
        }
    }

    enum ChartData {
        static let title = AppLocalizedString("jetpackStats.chartData.title", value: "Chart Data", comment: "Title for chart data screen")
        static let total = AppLocalizedString("jetpackStats.chartData.total", value: "Total", comment: "Label for total value")
        static let previous = AppLocalizedString("jetpackStats.chartData.previous", value: "Previous", comment: "Label for previous value")
        static let change = AppLocalizedString("jetpackStats.chartData.change", value: "Change", comment: "Label for change value")
        static let detailedData = AppLocalizedString("jetpackStats.chartData.detailedData", value: "Detailed Data", comment: "Section title for detailed data")
        static let date = AppLocalizedString("jetpackStats.chartData.date", value: "DATE", comment: "Column header for date")
        static let value = AppLocalizedString("jetpackStats.chartData.value", value: "VALUE", comment: "Column header for value")
    }
}
