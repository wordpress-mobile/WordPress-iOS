import SwiftUI
import WidgetKit

struct TodayWidgetView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    let content: TodayWidgetContent

    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall:
            TodayWidgetSmallView(content: content)
        case .systemMedium:
            TodayWidgetMediumView(content: content)
        default:
            HStack {}
        }
    }
}

struct TodayWidgetSmallView: View {
    let content: TodayWidgetContent

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                FlexibleCard(axis: .vertical, title: Constants.todayTitle, value: LocalizedStringKey(content.siteTitle))

                Spacer()
                VerticalCard(title: Constants.viewsTitle, value: "\(content.views)", largeTitles: true)
            }
            Spacer()
        }
        .background(Color(.yellow))
        .padding(.all, Constants.padding)
    }
}

struct TodayWidgetMediumView: View {
    let content: TodayWidgetContent

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                FlexibleCard(axis: .horizontal, title: Constants.todayTitle, value: LocalizedStringKey(content.siteTitle))
                Spacer()
                makeHorizontalView(title1: Constants.viewsTitle, value1: "\(content.views)", title2: Constants.visitorsTitle, value2: "\(content.visitors)")
                Spacer()
                makeHorizontalView(title1: Constants.likesTitle, value1: "\(content.likes)", title2: Constants.commentsTitle, value2: "\(content.comments)")
            }
        }
        .padding(.all, Constants.padding)
    }

    private func makeHorizontalView(title1: LocalizedStringKey, value1: LocalizedStringKey, title2: LocalizedStringKey, value2: LocalizedStringKey) -> some View {
        HStack {
            VerticalCard(title: title1, value: value1, largeTitles: false)
            Spacer()
            Spacer()
            VerticalCard(title: title2, value: value2, largeTitles: false)
            Spacer()
        }
    }
}

struct FlexibleCard: View {
    let axis: Axis
    let title: LocalizedStringKey
    let value: LocalizedStringKey

    private var descriptionView: some View {
        Text(value)
            .font(.footnote)
            .fontWeight(.semibold)
            .lineLimit(Constants.siteTitleLines)
            .foregroundColor(Color(.label))
    }

    private var titleView: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.regular)
            .foregroundColor(Color(.secondaryLabel))
    }

    var body: some View {
        switch axis {
        case .vertical:
            VStack(alignment: .leading) {
                descriptionView
                titleView
            }

        case .horizontal:
            HStack {
                descriptionView
                Spacer()
                titleView
            }
        }
    }
}

struct VerticalCard: View {
    let title: LocalizedStringKey
    let value: LocalizedStringKey
    let largeTitles: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color(Constants.viewsTitleColorName))

            Text(value)
                .font(titleFont)
                .foregroundColor(Color(.label))
        }
    }

    private var titleFont: Font {
        largeTitles ? .largeTitle : .title
    }
}

private enum Constants {
    // TODO - TODAYWIDGET: SwiftUI should be able to automatically localize strings,
    // so let's not use NSLocalizedString for now and check how this will fit in our existing system
    // Titles
    static let todayTitle: LocalizedStringKey = "Today"
    static let viewsTitle: LocalizedStringKey = "Views"
    static let visitorsTitle: LocalizedStringKey = "Visitors"
    static let likesTitle: LocalizedStringKey = "Likes"
    static let commentsTitle: LocalizedStringKey = "Comments"

    // Overall Appearance
    static let padding: CGFloat = 16

    // Site Title
    static let siteTitleLines = 2

    // Views
    static let viewsTitleColorName = "Blue50"
}

struct TodayWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        TodayWidgetView(content: staticModel)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
