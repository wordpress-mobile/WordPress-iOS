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

        case .siteSelected(let content):

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
