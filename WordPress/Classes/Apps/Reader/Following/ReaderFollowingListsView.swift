import UIKit
import SwiftUI
import Combine
import WordPressUI

struct ReaderFollowingListsView: View {
    let viewModel: ReaderFollowingViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)]
    )
    private var lists: FetchedResults<ReaderListTopic>

    var body: some View {
        if lists.isEmpty {
            EmptyStateView(Strings.emptyTitle, systemImage: "list.clipboard", description: Strings.emptyDetails)
                .frame(height: 420)
                .listRowSeparator(.hidden)
        } else {
            items
        }
    }

    private var items: some View {
        ForEach(lists, id: \.self) { list in
            Button {
                viewModel.navigate(to: .topic(list))
            } label: {
                Label {
                    Text(list.title)
                        .lineLimit(1)
                } icon: {
                    ReaderSidebarImage(name: "reader-menu-list")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private enum Strings {
    static let emptyTitle = NSLocalizedString("reader.following.lists.emptyTitle", value: "Lists Empty", comment: "Empty state view")
    static let emptyDetails = NSLocalizedString("reader.following.lists.emptyTitle", value: "Create lists to following different topics in one convenient feed", comment: "Empty state view")
}
