import SwiftUI

struct ReaderNavigationButton: View {

    @ObservedObject var viewModel: ReaderTabViewModel

    var body: some View {
        Menu {
            ForEach(viewModel.filterItems, id: \.self) { item in
                menuButton(for: item)
            }
            if viewModel.listItems.count > 0 {
                Section {
                    if viewModel.listItems.count > 2 {
                        Menu {
                            ForEach(viewModel.listItems, id: \.self) { item in
                                menuButton(for: item)
                            }
                        } label: {
                            Text(Strings.lists)
                        }
                    } else {
                        ForEach(viewModel.listItems, id: \.self) { item in
                            menuButton(for: item)
                        }
                    }
                }
            }
        } label: {
            if let selectedItem = viewModel.selectedItem {
                menuLabel(for: selectedItem)
            }
        }
        .accessibilityIdentifier("reader-navigation-button")
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            WPAnalytics.track(.readerDropdownOpened)
        }
    }

    private func menuLabel(for item: ReaderTabItem) -> some View {
        HStack(spacing: 4.0) {
            item.image
                .frame(width: 24.0, height: 24.0)
                .foregroundColor(Colors.primary)
            Text(item.title)
                .foregroundStyle(Colors.primary)
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 24.0)
            Image("reader-menu-chevron-down")
                .frame(width: 16.0, height: 16.0)
                .foregroundColor(Colors.primary)
        }
        .padding(.vertical, 6.0)
        .padding(.leading, item.image == nil ? 16.0 : 8.0)
        .padding(.trailing, 12.0)
        .background(Colors.background)
        .clipShape(Capsule())
    }

    private func menuButton(for item: ReaderTabItem) -> some View {
        let index = viewModel.tabItems.firstIndex(of: item) ?? 0
        let eventId = item.dropdownEventId
        return Button {
            viewModel.showTab(at: index)
            WPAnalytics.track(.readerDropdownItemTapped, properties: ["id": eventId])
        } label: {
            HStack {
                Text(item.title)
                Spacer()
                item.image
            }
        }
    }

    struct Colors {
        static let primary: Color = Color(uiColor: .systemBackground)
        static let background: Color = Color(uiColor: .text)
    }

    struct Strings {
        static let lists = NSLocalizedString(
            "reader.navigation.menu.lists",
            value: "Lists",
            comment: "Reader navigation menu item for the lists menu group"
        )
    }

}

private extension ReaderTabItem {

    var image: Image? {
        if content.type == .saved {
            return Image("reader-menu-saved")
        }

        switch content.topicType {
        case .discover:
            return Image("reader-menu-jetpack")
        case .following:
            return Image("reader-menu-subscriptions")
        case .likes:
            return Image("reader-menu-star-outline")
        default:
            return nil
        }
    }

    var dropdownEventId: String {
        if let topic = content.topic as? ReaderTeamTopic,
           topic.slug == ReaderTeamTopic.a8cSlug {
            return "a8c"
        }

        if content.topic is ReaderListTopic {
            return "list"
        }

        if content.type == .saved {
            return "saved"
        }

        switch content.topicType {
        case .discover:
            return "discover"
        case .following:
            return "following"
        case .likes:
            return "liked"
        default:
            return "unknown"
        }
    }

}
