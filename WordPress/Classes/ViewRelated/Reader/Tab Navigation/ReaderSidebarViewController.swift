import UIKit
import SwiftUI

final class ReaderSidebarViewController: UIHostingController<ReaderSidebar> {
    init(viewModel: ReaderTabViewModel) {
        super.init(rootView: ReaderSidebar(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// TODO: (wpsidebar) reimplement – this is just for the demonstration
struct ReaderSidebar: View {
    @ObservedObject var viewModel: ReaderTabViewModel

    var body: some View {
        List(selection: selection) {
            ForEach(viewModel.filterItems) {
                menuButton(for: $0)
            }
            // TODO: (wpsidebar) add support for lists
//            if item == viewModel.filterItems.last && viewModel.listItems.count > 0 {
//                listMenuItem
//            }
        }
        .listStyle(.sidebar)
        .navigationTitle(Strings.reader)
    }

    // TODO: (wpsidebar) refactor selection

    private var selection: Binding<ReaderTabItem?> {
        Binding {
            viewModel.selectedItem
        } set: { item in
            if let item, let index = viewModel.filterItems.firstIndex(of: item) {
                viewModel.showTab(at: index)
            }
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

    private func menuButton(for item: ReaderTabItem) -> some View {
        // TODO: (wpsidebar) implement tracking
        // let index = viewModel.tabItems.firstIndex(of: item) ?? 0
        //        let eventId = item.dropdownEventId
        //        return Button {
        //            viewModel.showTab(at: index)
        //            WPAnalytics.track(.readerDropdownItemTapped, properties: ["id": eventId])
        //        } label: {
        //        }
        Label {
            Text(item.title)
        } icon: {
            item.image
        }
        .tag(item)
        .accessibilityIdentifier(item.accessibilityIdentifier)
    }
}

private struct Strings {
    static let reader = NSLocalizedString("readerSidebar.navigationTitle", value: "Reader", comment: "Reader sidebar title on iPad")
    static let lists = ReaderNavigationButton.Strings.lists
}
