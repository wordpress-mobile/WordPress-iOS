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
                                 siteNameTitle:
                                    Constants.siteNameTitle,
                                 viewsTitle: Constants.viewsTitle)
                .padding(.all, Constants.padding)
        case .systemMedium:
            TodayWidgetMediumView(content: content,
                                  siteNameTitle: Constants.siteNameTitle,
                                  viewsTitle: Constants.viewsTitle,
                                  visitorsTitle: Constants.visitorsTitle,
                                  likesTitle: Constants.likesTitle,
                                  commentsTitle: Constants.commentsTitle)
                .padding(.all, Constants.padding)
        default:
            Text("View is unavailable")
        }
    }
}

// MARK: - Constants
extension TodayWidgetView {

    private enum Constants {
        // Titles
        static let siteNameTitle: LocalizedStringKey = "Today"
        static let viewsTitle: LocalizedStringKey = "Views"
        static let visitorsTitle: LocalizedStringKey = "Visitors"
        static let likesTitle: LocalizedStringKey = "Likes"
        static let commentsTitle: LocalizedStringKey = "Comments"

        // Padding
        static let padding: CGFloat = 16
    }
}

struct TodayWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        TodayWidgetView(content: staticModel)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
