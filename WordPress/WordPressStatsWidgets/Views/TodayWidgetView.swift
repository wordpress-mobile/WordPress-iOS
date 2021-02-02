import SwiftUI
import WidgetKit

struct TodayWidgetView: View {
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
                    TodayWidgetSmallView(content: content,
                                         widgetTitle: LocalizableStrings.widgetTitle,
                                         viewsTitle: LocalizableStrings.viewsTitle)
                        .padding()

                case .systemMedium:
                    TodayWidgetMediumView(content: content,
                                          widgetTitle: LocalizableStrings.widgetTitle,
                                          viewsTitle: LocalizableStrings.viewsTitle,
                                          visitorsTitle: LocalizableStrings.visitorsTitle,
                                          likesTitle: LocalizableStrings.likesTitle,
                                          commentsTitle: LocalizableStrings.commentsTitle)
                        .padding()

                default:
                    Text("View is unavailable")
                }
            }
        }
    }
}
