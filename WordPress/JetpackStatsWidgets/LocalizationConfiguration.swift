import Foundation

extension AppConfiguration.Widget {
    struct Localization {
        static let unconfiguredViewTodayTitle = AppLocalizedString("widget.jetpack.today.unconfigured.view.title",
                                                                   value: "Log in to Jetpack to see today's stats.",
                                                                   comment: "Title of the unconfigured view in today widget")
        static let unconfiguredViewThisWeekTitle = AppLocalizedString("widget.jetpack.thisweek.unconfigured.view.title",
                                                                      value: "Log in to Jetpack to see this week's stats.",
                                                                      comment: "Title of the unconfigured view in this week widget")
        static let unconfiguredViewAllTimeTitle = AppLocalizedString("widget.jetpack.alltime.unconfigured.view.title",
                                                                     value: "Log in to Jetpack to see all time stats.",
                                                                     comment: "Title of the unconfigured view in all time widget")

        // iOS13 Widgets
        static let configureToday = AppLocalizedString("Display your site stats for today here. Configure in the Jetpack app in your site stats.", comment: "Unconfigured stats today widget helper text for Jetpack app")
        static let configureAllTime = AppLocalizedString("Display your all-time site stats here. Configure in the Jetpack app in your site stats.", comment: "Unconfigured stats all-time widget helper text for Jetpack app")
        static let configureThisWeek = AppLocalizedString("Display your site stats for this week here. Configure in the Jetpackk app in your site stats.", comment: "Unconfigured stats this week widget helper text for Jetpack app")
        static let openApp = AppLocalizedString("Open Jetpack", comment: "Today widget label to launch Jetpack app")
    }
}
