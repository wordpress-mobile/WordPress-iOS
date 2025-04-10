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
