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
        static let widgetTitle = LocalizedStringKey("widget.today.title.label", defaultValue: "Today", comment: "Title of today widget")
        static let viewsTitle = LocalizedStringKey("widget.today.views.label", defaultValue: "Views", comment: "Title of views label in today widget")
        static let visitorsTitle = LocalizedStringKey("widget.today.visitors.label", defaultValue: "Visitors", comment: "Title of visitors label in today widget")
        static let likesTitle = LocalizedStringKey("widget.today.likes.label", defaultValue: "Likes", comment: "Title of likes label in today widget")
        static let commentsTitle = LocalizedStringKey("widget.today.comments.label", defaultValue: "Comments", comment: "Title of comments label in today widget")
    }
}


extension LocalizedStringKey {
    static let defaultBundle = Bundle(for: HomeWidgetTodayRemoteService.self)

    init(_ key: String, defaultValue: String, comment: String) {
        self.init(NSLocalizedString(key, tableName: nil, bundle: Self.defaultBundle, value: defaultValue, comment: comment))
    }
}
