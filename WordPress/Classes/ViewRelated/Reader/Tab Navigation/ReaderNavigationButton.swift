import SwiftUI

struct ReaderNavigationButton: View {

    @ObservedObject var viewModel: ReaderTabViewModel

    var body: some View {
        Menu {
            ForEach(menuItemGroups, id: \.self) { group in
                Section {
                    ForEach(group, id: \.self) { item in
                        menuButton(for: item)
                    }
                    if group == menuItemGroups.last && viewModel.listItems.count > 0 {
                        if !FeatureFlag.readerTagsFeed.enabled {
                            Divider()
                        }
                        listMenuItem
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

    private var menuItemGroups: [[ReaderTabItem]] {
        var items: [[ReaderTabItem]] = [[]]
        var currentGroup = 0
        for item in viewModel.filterItems {
            if item.content.type == .saved || item.content.type == .tags {
                currentGroup += 1
                items.append([item])
                continue
            }
            items[currentGroup].append(item)
        }

        return items
    }

    @ViewBuilder
    private var listMenuItem: some View {
        if viewModel.listItems.count > 2 {
            Menu {
                ForEach(viewModel.listItems, id: \.self) { item in
                    menuButton(for: item)
                }
            } label: {
                HStack {
                    Text(Strings.lists)
                    Spacer()
                    Image("reader-menu-list")
                }
            }
        } else {
            ForEach(viewModel.listItems, id: \.self) { item in
                menuButton(for: item)
            }
        }
    }

    private func menuLabel(for item: ReaderTabItem) -> some View {
        /// There's a bug/unexpected behavior with how `SwiftUI.Menu`'s label "twitches" when it's animated.
        /// Using `ZStack` is a hack to prevent the "container" view from twitching during animation.
        ZStack {
            // This is used for the background component.
            Capsule().fill(Colors.background)

            HStack(spacing: 4.0) {
                item.image
                    .frame(width: 24.0, height: 24.0)
                    .foregroundColor(Colors.primary)
                Text(item.title)
                    .foregroundStyle(Colors.primary)
                    .font(.subheadline.weight(.semibold))
                    .minimumScaleFactor(0.1) // prevents the text from truncating while in transition.
                    .frame(minHeight: 24.0)
                Image("reader-menu-chevron-down")
                    .frame(width: 16.0, height: 16.0)
                    .foregroundColor(Colors.primary)
            }
            .padding(.vertical, 6.0)
            .padding(.leading, item.image == nil ? 16.0 : 8.0)
            .padding(.trailing, 12.0)
        }
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
        .accessibilityIdentifier(item.accessibilityIdentifier)
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
        } else if content.type == .tags {
            return Image("reader-menu-tags")
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
        } else if content.type == .tags {
            return "tags"
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
