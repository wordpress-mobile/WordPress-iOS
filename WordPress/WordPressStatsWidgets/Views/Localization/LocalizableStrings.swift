import SwiftUI

enum LocalizableStrings {
    // Widget content
    static let widgetTitle = LocalizedStringKey("widget.today.title",
                                                defaultValue: "Today",
                                                comment: "Title of today widget")

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

    // Unconfigured view
    static let unconfiguredViewTitle = LocalizedStringKey("widget.today.unconfigured.view.title",
                                                          defaultValue: "Log in to WordPress to see today's stats.",
                                                          comment: "Title of the unconfigured view in today widget")

    // Preview
    static let previewDescription = LocalizedStringKey("widget.today.preview.description",
                                                       defaultValue: "Stay up to date with today's activity on your WordPress site.",
                                                       comment: "Description of today widget in the preview")

    // Errors
    static let unavailableViewTitle = LocalizedStringKey("widget.today.view.unavailable.title",
                                                         defaultValue: "View is unavailable",
                                                         comment: "Error message to show if a widget view is unavailable")
}
