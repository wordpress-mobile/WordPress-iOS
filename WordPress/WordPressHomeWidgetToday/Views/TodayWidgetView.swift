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
        static let widgetTitle = LocalizedStringKey("TODAY_WIDGET_TODAY_LABEL", defaultValue: "Today", comment: "Title of today widget")
        static let viewsTitle = LocalizedStringKey("TODAY_WIDGET_VIEWS_LABEL", defaultValue: "Views", comment: "Title of views label in today widget")
        static let visitorsTitle = LocalizedStringKey("TODAY_WIDGET_VISITORS_LABEL", defaultValue: "Visitors", comment: "Title of visitors label in today widget")
        static let likesTitle = LocalizedStringKey("TODAY_WIDGET_LIKES_LABEL", defaultValue: "Likes", comment: "Title of likes label in today widget")
        static let commentsTitle = LocalizedStringKey("TODAY_WIDGET_COMMENTS_LABEL", defaultValue: "Comments", comment: "Title of comments label in today widget")
    }
}


extension LocalizedStringKey {
    static let defaultBundle = Bundle(for: HomeWidgetTodayRemoteService.self)

    init(_ key: String, defaultValue: String, comment: String) {
        self.init(NSLocalizedString(key, tableName: nil, bundle: Self.defaultBundle, value: defaultValue, comment: comment))
    }
}
