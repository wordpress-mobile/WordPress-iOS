import SwiftUI
import WidgetKit

struct TodayWidgetView: View {
    let content: TodayWidgetContent

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(content.siteTitle)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .lineLimit(Constants.siteTitleLines)
                    .foregroundColor(Color(.label))

                Text(Constants.todayTitle)
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(Color(.secondaryLabel))

                Spacer()

                Text(Constants.viewsTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Constants.viewsTitleColor)

                Text("\(content.views)")
                    .font(.largeTitle)
                    .foregroundColor(Color(.label))
            }
            Spacer()
        }
        .padding(.all, Constants.padding)
    }

    private enum Constants {
        // TODO - TODAYWIDGET: SwiftUI should be able to automatically localize strings,
        // so let's not use NSLocalizedString for now and check how this will fit in our existing system
        // Titles
        static let todayTitle: LocalizedStringKey = "Today"
        static let viewsTitle: LocalizedStringKey  = "Views"
        static let visitorsTitle: LocalizedStringKey  = "Visitors"
        static let likesTitle: LocalizedStringKey  = "Likes"
        static let commentsTitle: LocalizedStringKey  = "Comments"

        // Overall Appearance
        static let padding: CGFloat = 16

        // Site Title
        static let siteTitleLines = 2

        // Views
        static let viewsTitleColor = Color("Blue50")
    }
}

struct TodayWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        TodayWidgetView(content: staticModel)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
