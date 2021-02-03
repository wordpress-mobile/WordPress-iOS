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

        case .siteSelected(let content):
            /// - TODO: Handle at least one more case (all time widget)
            if let content = content as? HomeWidgetTodayData {
                switch family {

                case .systemSmall:
                    SingleStatView(content: content,
                                         widgetTitle: LocalizableStrings.todayWidgetTitle,
                                         title: LocalizableStrings.viewsTitle)
                        .padding()

                case .systemMedium:
                    FourStatsView(content: content,
                                          widgetTitle: LocalizableStrings.todayWidgetTitle,
                                          upperLeftTitle: LocalizableStrings.viewsTitle,
                                          upperRightTitle: LocalizableStrings.visitorsTitle,
                                          lowerLeftTitle: LocalizableStrings.likesTitle,
                                          lowerRightTitle: LocalizableStrings.commentsTitle)
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
                        .padding()

                case .systemMedium:
                    FourStatsView(content: content,
                                          widgetTitle: LocalizableStrings.allTimeWidgetTitle,
                                          upperLeftTitle: LocalizableStrings.viewsTitle,
                                          upperRightTitle: LocalizableStrings.visitorsTitle,
                                          lowerLeftTitle: LocalizableStrings.postsTitle,
                                          lowerRightTitle: LocalizableStrings.bestViewsTitle)
                        .padding()

                default:
                    Text("View is unavailable")
                }
            }
        }
    }
}
