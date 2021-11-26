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
    // No data view
    static let noDataViewTitle = AppLocalizedString("widget.today.nodata.view.title",
                                                    value: "Unable to load site stats.",
                                                    comment: "Title of the nodata view in today widget")

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
}
