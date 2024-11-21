import UIKit
import SwiftUI
import Combine
import WordPressUI

struct ReaderSidebarListsSection: View {
    let viewModel: ReaderSidebarViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)]
    )
    private var lists: FetchedResults<ReaderListTopic>

    var body: some View {
        ForEach(lists, id: \.self, content: ReaderSidebarListCell.init)
    }
}

struct ReaderSidebarListCell: View {
    let list: ReaderListTopic

    var body: some View {
        Label {
            Text(list.title)
                .lineLimit(1)
        } icon: {
            Image(systemName: "list.star")
                .foregroundStyle(.secondary)
        }
        .tag(ReaderSidebarItem.list(TaggedManagedObjectID(list)))
    }
}
