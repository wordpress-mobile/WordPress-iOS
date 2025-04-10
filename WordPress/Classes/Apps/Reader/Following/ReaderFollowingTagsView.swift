import UIKit
import SwiftUI
import Combine
import WordPressUI

struct ReaderFollowingTagsView: View {
    let viewModel: ReaderFollowingViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)],
        predicate: ReaderSidebarTagsSection.predicate
    )
    private var tags: FetchedResults<ReaderTagTopic>

    static let predicate = NSPredicate(format: "following == YES AND showInMenu == YES AND type == 'tag'")

    var body: some View {
        ForEach(tags, id: \.self) { tag in
            Button {
                viewModel.navigate(to: .topic(tag))
            } label: {
                Label {
                    Text(tag.title)
                        .lineLimit(1)
                } icon: {
                    ReaderSidebarImage(name: "reader-menu-tag")
                        .foregroundStyle(.secondary)
                }
            }
            .swipeActions(edge: .trailing) {
                Button(SharedStrings.Reader.unfollow, role: .destructive) {
                    ReaderTagsHelper().unfollow(tag)
                }.tint(.red)
            }
            .contextMenu(menuItems: {
                Button(SharedStrings.Reader.unfollow, systemImage: "trash", role: .destructive) {
                    ReaderTagsHelper().unfollow(tag)
                }
            }, preview: {
                ReaderTopicPreviewView(topic: tag)
            })
        }
        .onDelete(perform: delete)

        Button {
            viewModel.navigate(to: .discoverTags)
        } label: {
            Label {
                Text(Strings.discoverTags)
            } icon: {
                ReaderSidebarImage(name: "reader-menu-explorer")
            }
        }
        .listItemTint(AppColor.primary)
    }

    func delete(at offsets: IndexSet) {
        let tags = offsets.map { self.tags[$0] }
        for tag in tags {
            ReaderTagsHelper().unfollow(tag)
        }
    }
}

private struct Strings {
    static let addTag = NSLocalizedString("reader.following.tags.addTag", value: "Add tag", comment: "Button title")
    static let discoverTags = NSLocalizedString("reader.following.tags.discoverTags", value: "Discover More Tags", comment: "Button title")
}
