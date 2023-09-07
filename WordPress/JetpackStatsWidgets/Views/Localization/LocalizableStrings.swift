import SwiftUI

enum LocalizableStrings {
    // Today Widget title
    static let todayWidgetTitle = AppLocalizedString("widget.today.title",
                                                     value: "Today",
                                                     comment: "Title of today widget")

    // All Time Widget title
    static let allTimeWidgetTitle = AppLocalizedString("widget.alltime.title",
                                                       value: "All Time",
                                                       comment: "Title of all time widget")

    // This Week Widget title
    static let thisWeekWidgetTitle = AppLocalizedString("widget.thisweek.title",
                                                        value: "This Week",
                                                        comment: "Title of this week widget")

    // Lock Screen Widgets title
    static let todayViewsWidgetPreviewTitle = AppLocalizedString("widget.todayViews.previewTitle",
                                                            value: "Today's Views",
                                                            comment: "Preview title of today's views widget")
    static let todayViewsVisitorsWidgetPreviewTitle = AppLocalizedString("widget.todayViewsVisitors.previewTitle",
                                                                         value: "Today's Views & Visitors",
                                                                         comment: "Preview title of today's views and visitors widget")
    static let todayLikesCommentsWidgetPreviewTitle = AppLocalizedString("widget.todayLikesComments.previewTitle",
                                                                         value: "Today's Likes & Comments",
                                                                         comment: "Preview title of today's likes and commnets widget")
    static let allTimeViewsWidgetPreviewTitle = AppLocalizedString("widget.allTimeViews.previewTitle",
                                                                   value: "All-Time Views",
                                                                   comment: "Preview title of all-time views widget")
    static let allTimeViewsVisitorsWidgetPreviewTitle = AppLocalizedString("widget.allTimeViewsVisitors.previewTitle",
                                                                           value: "All-Time Views & Visitors",
                                                                           comment: "Preview title of all-time views and visitors widget")
    static let allTimePostMostViewsWidgetPreviewTitle = AppLocalizedString("widget.allTimePostViews.previewTitle",
                                                                           value: "All-Time Posts & Most Views",
                                                                           comment: "Preview title of all-time posts and most views widget")

    static let viewsInTodayTitle = AppLocalizedString("widget.lockscreen.todayview.label",
                                                   value: "Views Today",
                                                   comment: "Title of the one-liner information consist of views field and today date range in lock screen today views widget")

    static let allTimeViewsTitle = AppLocalizedString("widget.lockscreen.alltimeview.label",
                                                      value: "All-Time Views",
                                                      comment: "Title of the one-liner information consist of views field and all time date range in lock screen all time views widget")

    static let viewsThisWeekTitle = AppLocalizedString("widget.lockscreen.thisweek.label",
                                                       value: "Views This Week",
                                                       comment: "Title of the one-liner information consist of views field and this week date range in lock screen this week views widget")

    static let chartViewsLabel = AppLocalizedString("widget.lockscreen.chart.label",
                                                    value: "%1$@ views",
                                                    comment: "Label shown next to a chart displaying daily views. %1$@ is a placeholder for a number")

    static let chartXAxisLabel = AppLocalizedString("widget.lockscreen.chart.xaxislabel",
                                                    value: "Date",
                                                    comment: "Label shown next to a chart explaining horizontal axis")

    static let chartYAxisLabel = AppLocalizedString("widget.lockscreen.chart.yaxislabel",
                                                    value: "Views",
                                                    comment: "Label shown next to a chart explaining vertical axis")

    // Widgets content
    static let viewsTitle = AppLocalizedString("widget.today.views.label",
                                               value: "Views",
                                               comment: "Title of views label in today widget")

    static let visitorsTitle = AppLocalizedString("widget.today.visitors.label",
                                                  value: "Visitors",
                                                  comment: "Title of visitors label in today widget")

    static let likesTitle = AppLocalizedString("widget.today.likes.label",
                                               value: "Likes",
                                               comment: "Title of likes label in today widget")

    static let commentsTitle = AppLocalizedString("widget.today.comments.label",
                                                  value: "Comments",
                                                  comment: "Title of comments label in today widget")

    static let postsTitle = AppLocalizedString("widget.alltime.posts.label",
                                               value: "Posts",
                                               comment: "Title of posts label in all time widget")

    static let bestViewsTitle = AppLocalizedString("widget.alltime.bestviews.label",
                                                   value: "Best views ever",
                                                   comment: "Title of best views ever label in all time widget")

    static let bestViewsShortTitle = AppLocalizedString("widget.alltime.bestviewsshort.label",
                                                        value: "Most Views",
                                                        comment: "Title of the label which displays the number of the most daily views the site has ever had. Keep the translation as short as possible.")
    // Unconfigured view
    static let unconfiguredViewTodayTitle = AppLocalizedString("widget.today.unconfigured.view.title",
                                                               value: "Log in to WordPress to see today's stats.",
                                                               comment: "Title of the unconfigured view in today widget")

    static let unconfiguredViewAllTimeTitle = AppLocalizedString("widget.alltime.unconfigured.view.title",
                                                                 value: "Log in to WordPress to see all time stats.",
                                                                 comment: "Title of the unconfigured view in all time widget")

    static let unconfiguredViewThisWeekTitle = AppLocalizedString("widget.thisweek.unconfigured.view.title",
                                                                  value: "Log in to WordPress to see this week's stats.",
                                                                  comment: "Title of the unconfigured view in this week widget")

    static let unconfiguredViewJetpackTodayTitle = AppLocalizedString("widget.jetpack.today.unconfigured.view.title",
                                                                      value: "Log in to Jetpack to see today's stats.",
                                                                      comment: "Title of the unconfigured view in today widget")

    static let unconfiguredViewJetpackAllTimeTitle = AppLocalizedString("widget.jetpack.alltime.unconfigured.view.title",
                                                                        value: "Log in to Jetpack to see all time stats.",
                                                                        comment: "Title of the unconfigured view in all time widget")

    static let unconfiguredViewJetpackThisWeekTitle = AppLocalizedString("widget.jetpack.thisweek.unconfigured.view.title",
                                                                         value: "Log in to Jetpack to see this week's stats.",
                                                                         comment: "Title of the unconfigured view in this week widget")
    // No data view
    static let noDataViewTitle = AppLocalizedString("widget.today.nodata.view.fallbackTitle",
                                                    value: "Unable to load site stats.",
                                                    comment: "Fallback title of the no data view in the stats widget")

    static let noDataViewTodayTitle = AppLocalizedString("widget.today.nodata.view.title",
                                                         value: "Unable to load today's stats.",
                                                         comment: "Title of the no data view in today widget")

    static let noDataViewAllTimeTitle = AppLocalizedString("widget.alltime.nodata.view.title",
                                                           value: "Unable to load all time stats.",
                                                           comment: "Title of the no data view in all time widget")

    static let noDataViewThisWeekTitle = AppLocalizedString("widget.thisweek.nodata.view.title",
                                                            value: "Unable to load this week's stats.",
                                                            comment: "Title of the no data view in this week widget")

    // No site view
    static let noSiteViewTodayTitle = AppLocalizedString("widget.today.nosite.view.title",
                                                         value: "Create or add a site to see today's stats.",
                                                         comment: "Title of the no site view in today widget")

    static let noSiteViewAllTimeTitle = AppLocalizedString("widget.alltime.nosite.view.title",
                                                           value: "Create or add a site to see all time stats.",
                                                           comment: "Title of the no site view in all time widget")

    static let noSiteViewThisWeekTitle = AppLocalizedString("widget.thisweek.nosite.view.title",
                                                            value: "Create or add a site to see this week's stats.",
                                                            comment: "Title of the no site view in this week widget")

    // Today Widget Preview
    static let todayPreviewDescription = AppLocalizedString("widget.today.preview.description",
                                                            value: "Stay up to date with today's activity on your WordPress site.",
                                                            comment: "Description of today widget in the preview")
    // All Time Widget preview
    static let allTimePreviewDescription = AppLocalizedString("widget.alltime.preview.description",
                                                              value: "Stay up to date with all time activity on your WordPress site.",
                                                              comment: "Description of all time widget in the preview")

    // This Week Widget preview
    static let thisWeekPreviewDescription = AppLocalizedString("widget.thisweek.preview.description",
                                                               value: "Stay up to date with this week activity on your WordPress site.",
                                                               comment: "Description of all time widget in the preview")

    // Errors
    static let unavailableViewTitle = AppLocalizedString("widget.today.view.unavailable.title",
                                                         value: "View is unavailable",
                                                         comment: "Error message to show if a widget view is unavailable")

    // Stats disabled view
    static let statsDisabledViewTitle = AppLocalizedString("widget.today.disabled.view.title",
                                                           value: "Stats have moved to the Jetpack app. Switching is free and only takes a minute.",
                                                           comment: "Title of the disabled view in today widget")
}
