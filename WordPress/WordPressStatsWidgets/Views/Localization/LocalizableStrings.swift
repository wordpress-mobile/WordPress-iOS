import SwiftUI

enum LocalizableStrings {
    // Today Widget title
    static let todayWidgetTitle = LocalizedStringKey("widget.today.title",
                                                defaultValue: "Today",
                                                comment: "Title of today widget")

    // All Time Widget title
    static let allTimeWidgetTitle = LocalizedStringKey("widget.alltime.title",
                                                       defaultValue: "All Time",
                                                       comment: "Title of all time widget")

    // This Week Widget title
    static let thisWeekWidgetTitle = LocalizedStringKey("widget.thisweek.title",
                                                       defaultValue: "This Week",
                                                       comment: "Title of this week widget")

    // Widgets content
    static let viewsTitle = LocalizedStringKey("widget.today.views.label",
                                               defaultValue: "Views",
                                               comment: "Title of views label in today widget")

    static let visitorsTitle = LocalizedStringKey("widget.today.visitors.label",
                                                  defaultValue: "Visitors",
                                                  comment: "Title of visitors label in today widget")

    static let likesTitle = LocalizedStringKey("widget.today.likes.label",
                                               defaultValue: "Likes",
                                               comment: "Title of likes label in today widget")

    static let commentsTitle = LocalizedStringKey("widget.today.comments.label",
                                                  defaultValue: "Comments",
                                                  comment: "Title of comments label in today widget")

    static let postsTitle = LocalizedStringKey("widget.alltime.posts.label",
                                               defaultValue: "Posts",
                                               comment: "Title of posts label in all time widget")

    static let bestViewsTitle = LocalizedStringKey("widget.alltime.bestviews.label",
                                                   defaultValue: "Best views ever",
                                                   comment: "Title of best views ever label in all time widget")
    // Unconfigured view
    static let unconfiguredViewTodayTitle = LocalizedStringKey("widget.today.unconfigured.view.title",
                                                          defaultValue: "Log in to WordPress to see today's stats.",
                                                          comment: "Title of the unconfigured view in today widget")

    static let unconfiguredViewAllTimeTitle = LocalizedStringKey("widget.alltime.unconfigured.view.title",
                                                          defaultValue: "Log in to WordPress to see all time stats.",
                                                          comment: "Title of the unconfigured view in all time widget")

    static let unconfiguredViewThisWeekTitle = LocalizedStringKey("widget.thisweek.unconfigured.view.title",
                                                          defaultValue: "Log in to WordPress to see this week's stats.",
                                                          comment: "Title of the unconfigured view in this week widget")
    // No data view
    static let noDataViewTitle = LocalizedStringKey("widget.today.nodata.view.title",
                                                          defaultValue: "Unable to load site stats.",
                                                          comment: "Title of the nodata view in today widget")

    // Today Widget Preview
    static let todayPreviewDescription = LocalizedStringKey("widget.today.preview.description",
                                                       defaultValue: "Stay up to date with today's activity on your WordPress site.",
                                                       comment: "Description of today widget in the preview")
    // All Time Widget preview
    static let allTimePreviewDescription = LocalizedStringKey("widget.alltime.preview.description",
                                                              defaultValue: "Stay up to date with all time activity on your WordPress site.",
                                                              comment: "Description of all time widget in the preview")

    // This Week Widget preview
    static let thisWeekPreviewDescription = LocalizedStringKey("widget.thisweek.preview.description",
                                                              defaultValue: "Stay up to date with this week activity on your WordPress site.",
                                                              comment: "Description of all time widget in the preview")

    // Errors
    static let unavailableViewTitle = LocalizedStringKey("widget.today.view.unavailable.title",
                                                         defaultValue: "View is unavailable",
                                                         comment: "Error message to show if a widget view is unavailable")
}
