import SwiftUI
import WidgetKit

struct StatsWidgetsView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    let timelineEntry: StatsWidgetEntry

    @ViewBuilder
    var body: some View {

        switch timelineEntry {

        case .loggedOut:
            UnconfiguredView()
                .widgetURL(nil)
                // This seems to prevent a bug where the URL for subsequent widget
                // types is being triggered if one isn't specified here.
        case .siteSelected(let content):
            if let content = content as? HomeWidgetTodayData {
                switch family {

                case .systemSmall:
                    SingleStatView(content: content,
                                         widgetTitle: LocalizableStrings.todayWidgetTitle,
                                         title: LocalizableStrings.viewsTitle)
                        .widgetURL(content.statsURL)
                        .padding()

                case .systemMedium:
                    MultiStatsView(content: content,
                                          widgetTitle: LocalizableStrings.todayWidgetTitle,
                                          upperLeftTitle: LocalizableStrings.viewsTitle,
                                          upperRightTitle: LocalizableStrings.visitorsTitle,
                                          lowerLeftTitle: LocalizableStrings.likesTitle,
                                          lowerRightTitle: LocalizableStrings.commentsTitle)
                        .widgetURL(content.statsURL)
                        .padding()

                default:
                    Text("View is unavailable")
                }
            } else if let content =  content as? HomeWidgetAllTimeData {
                switch family {

                case .systemSmall:
                    SingleStatView(content: content,
                                         widgetTitle: LocalizableStrings.allTimeWidgetTitle,
                                         title: LocalizableStrings.viewsTitle)
                        .widgetURL(content.statsURL)
                        .padding()

                case .systemMedium:
                    MultiStatsView(content: content,
                                          widgetTitle: LocalizableStrings.allTimeWidgetTitle,
                                          upperLeftTitle: LocalizableStrings.viewsTitle,
                                          upperRightTitle: LocalizableStrings.visitorsTitle,
                                          lowerLeftTitle: LocalizableStrings.postsTitle,
                                          lowerRightTitle: LocalizableStrings.bestViewsTitle)
                        .widgetURL(content.statsURL)
                        .padding()

                default:
                    Text("View is unavailable")
                }
            }
        }
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
