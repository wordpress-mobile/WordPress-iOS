import SwiftUI
import WidgetKit

struct TodayWidgetView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    let content: TodayWidgetContent

    @ViewBuilder
    var body: some View {
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

// MARK: - Constants
extension TodayWidgetView {

    private enum Constants {
        // Titles
        static let widgetTitle: LocalizedStringKey = "Today"
        static let viewsTitle: LocalizedStringKey = "Views"
        static let visitorsTitle: LocalizedStringKey = "Visitors"
        static let likesTitle: LocalizedStringKey = "Likes"
        static let commentsTitle: LocalizedStringKey = "Comments"

    }
}

struct TodayWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        TodayWidgetView(content: staticContent)
            .previewContext(WidgetPreviewContext(family: .systemSmall))

        TodayWidgetView(content: staticContent)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
