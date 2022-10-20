import Foundation

extension AppConfiguration.Widget {
    struct Localization {
        static let unconfiguredViewTodayTitle = AppLocalizedString("widget.today.unconfigured.view.title",
                                                                   value: "Log in to WordPress to see today's stats.",
                                                                   comment: "Title of the unconfigured view in today widget")
        static let unconfiguredViewThisWeekTitle = AppLocalizedString("widget.thisweek.unconfigured.view.title",
                                                                      value: "Log in to WordPress to see this week's stats.",
                                                                      comment: "Title of the unconfigured view in this week widget")
        static let unconfiguredViewAllTimeTitle = AppLocalizedString("widget.alltime.unconfigured.view.title",
                                                                     value: "Log in to WordPress to see all time stats.",
                                                                     comment: "Title of the unconfigured view in all time widget")

        // iOS13 Widgets
        static let configureToday = AppLocalizedString("Display your site stats for today here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats today widget helper text")
        static let configureAllTime = AppLocalizedString("Display your all-time site stats here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats all-time widget helper text")
        static let configureThisWeek = AppLocalizedString("Display your site stats for this week here. Configure in the WordPress app in your site stats.", comment: "Unconfigured stats this week widget helper text")
        static let openApp = AppLocalizedString("Open WordPress", comment: "Today widget label to launch WP app")
    }
}
