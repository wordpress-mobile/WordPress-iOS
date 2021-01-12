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
                                     widgetTitle: Constants.widgetTitle,
                                     viewsTitle: Constants.viewsTitle)
                    .padding()

            case .systemMedium:
                TodayWidgetMediumView(content: content,
                                      widgetTitle: Constants.widgetTitle,
                                      viewsTitle: Constants.viewsTitle,
                                      visitorsTitle: Constants.visitorsTitle,
                                      likesTitle: Constants.likesTitle,
                                      commentsTitle: Constants.commentsTitle)
                    .padding()

            default:
                Text("View is unavailable")
            }
        }
    }
}

// MARK: - Constants
extension TodayWidgetView {

    private enum Constants {
        // Titles
        static let widgetTitle: LocalizedStringKey = "TODAY_WIDGET_TODAY_LABEL"
        static let viewsTitle: LocalizedStringKey = "TODAY_WIDGET_VIEWS_LABEL"
        static let visitorsTitle: LocalizedStringKey = "TODAY_WIDGET_VISITORS_LABEL"
        static let likesTitle: LocalizedStringKey = "TODAY_WIDGET_LIKES_LABEL"
        static let commentsTitle: LocalizedStringKey = "TODAY_WIDGET_COMMENTS_LABEL"
    }
}
