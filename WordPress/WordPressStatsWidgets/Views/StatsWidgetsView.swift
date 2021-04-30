import SwiftUI
import WidgetKit

struct StatsWidgetsView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    let timelineEntry: StatsWidgetEntry

    @ViewBuilder
    var body: some View {

        switch timelineEntry {

        case .loggedOut(let widgetKind):
            UnconfiguredView(widgetKind: widgetKind)
                .widgetURL(nil)
                // This seems to prevent a bug where the URL for subsequent widget
                // types is being triggered if one isn't specified here.
        case .noData:
            UnconfiguredView(widgetKind: .noStats)
                .widgetURL(nil)

        case .siteSelected(let content, _):
            if let viewData = makeGroupedViewData(from: content) {
                switch family {

                case .systemSmall:
                    SingleStatView(viewData: viewData)
                        .widgetURL(viewData.statsURL)
                        .padding()

                case .systemMedium:
                    MultiStatsView(viewData: viewData)
                        .widgetURL(viewData.statsURL)
                        .padding()

                default:
                    Text("View is unavailable")
                }
            }

            if let viewData = makeListViewData(from: content) {
                let padding: CGFloat = family == .systemLarge ? 22 : 16
                ListStatsView(viewData: viewData)
                    .widgetURL(viewData.statsURL)
                    .padding(.all, padding)
            }
        }
    }
}

// MARK: - Helper methods
private extension StatsWidgetsView {

    func makeGroupedViewData(from widgetData: HomeWidgetData) -> GroupedViewData? {

        if let todayWidgetData = widgetData as? HomeWidgetTodayData {

            return GroupedViewData(widgetTitle: LocalizableStrings.todayWidgetTitle,
                                   siteName: todayWidgetData.siteName,
                                   upperLeftTitle: LocalizableStrings.viewsTitle,
                                   upperLeftValue: todayWidgetData.stats.views,
                                   upperRightTitle: LocalizableStrings.visitorsTitle,
                                   upperRightValue: todayWidgetData.stats.visitors,
                                   lowerLeftTitle: LocalizableStrings.likesTitle,
                                   lowerLeftValue: todayWidgetData.stats.likes,
                                   lowerRightTitle: LocalizableStrings.commentsTitle,
                                   lowerRightValue: todayWidgetData.stats.comments,
                                   statsURL: todayWidgetData.statsURL)
        }

        if let allTimeWidgetData = widgetData as? HomeWidgetAllTimeData {

            return GroupedViewData(widgetTitle: LocalizableStrings.allTimeWidgetTitle,
                                   siteName: allTimeWidgetData.siteName,
                                   upperLeftTitle: LocalizableStrings.viewsTitle,
                                   upperLeftValue: allTimeWidgetData.stats.views,
                                   upperRightTitle: LocalizableStrings.visitorsTitle,
                                   upperRightValue: allTimeWidgetData.stats.visitors,
                                   lowerLeftTitle: LocalizableStrings.postsTitle,
                                   lowerLeftValue: allTimeWidgetData.stats.posts,
                                   lowerRightTitle: LocalizableStrings.bestViewsTitle,
                                   lowerRightValue: allTimeWidgetData.stats.bestViews,
                                   statsURL: allTimeWidgetData.statsURL)
        }
        return nil
    }

    func makeListViewData(from widgetData: HomeWidgetData) -> ListViewData? {
        guard let thisWeekWidgetData = widgetData as? HomeWidgetThisWeekData else {
            return nil
        }
        return ListViewData(widgetTitle: LocalizableStrings.thisWeekWidgetTitle,
                            siteName: thisWeekWidgetData.siteName,
                            items: thisWeekWidgetData.stats.days,
                            statsURL: thisWeekWidgetData.statsURL)
    }
}


private extension HomeWidgetTodayData {
    static let statsUrl = "https://wordpress.com/stats/day/"

    var statsURL: URL? {
        URL(string: Self.statsUrl + "\(siteID)?source=widget")
    }
}


private extension HomeWidgetAllTimeData {
    static let statsUrl = "https://wordpress.com/stats/insights/"

    var statsURL: URL? {
        URL(string: Self.statsUrl + "\(siteID)?source=widget")
    }
}


private extension HomeWidgetThisWeekData {
    static let statsUrl = "https://wordpress.com/stats/week/"

    var statsURL: URL? {
        URL(string: Self.statsUrl + "\(siteID)?source=widget")
    }
}
