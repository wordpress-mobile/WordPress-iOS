import SwiftUI
import WidgetKit

struct TodayWidgetView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    let timelineEntry: HomeWidgetTodayEntry

    @ViewBuilder
    var body: some View {

        switch timelineEntry {

        case .loggedOut:
            UnconfiguredView()
                .widgetURL(nil)
                // This seems to prevent a bug where the URL for subsequent widget
                // types is being triggered if one isn't specified here.
        case .siteSelected(let content):

            switch family {

            case .systemSmall:
                TodayWidgetSmallView(content: content,
                                     widgetTitle: LocalizableStrings.widgetTitle,
                                     viewsTitle: LocalizableStrings.viewsTitle)
                    .widgetURL(content.statsURL)
                    .padding()

            case .systemMedium:
                TodayWidgetMediumView(content: content,
                                      widgetTitle: LocalizableStrings.widgetTitle,
                                      viewsTitle: LocalizableStrings.viewsTitle,
                                      visitorsTitle: LocalizableStrings.visitorsTitle,
                                      likesTitle: LocalizableStrings.likesTitle,
                                      commentsTitle: LocalizableStrings.commentsTitle)
                    .widgetURL(content.statsURL)
                    .padding()

            default:
                Text("View is unavailable")
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
