import UIKit
import SwiftUI
import Combine
import WordPressUI

struct ReaderSidebarTagsSection: View {
    let viewModel: ReaderSidebarViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.title, order: .forward)],
        predicate: ReaderSidebarTagsSection.predicate
    )
    private var tags: FetchedResults<ReaderTagTopic>

    static let predicate = NSPredicate(format: "following == YES AND showInMenu == YES AND type == 'tag'")

    var body: some View {
        ForEach(tags, id: \.self) { tag in
            Label {
                Text(tag.title)
                    .lineLimit(1)
            } icon: {
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
            }
            .tag(ReaderSidebarItem.tag(TaggedManagedObjectID(tag)))
            .swipeActions(edge: .trailing) {
                Button(SharedStrings.Reader.unfollow, role: .destructive) {
                    // TODO: (wpsidebar) implement
                }.tint(.red)
            }
        }
        .onDelete(perform: delete)

        Button {
            viewModel.navigate(.addTag)
        } label: {
            Label(Strings.addTag, systemImage: "plus.circle")
        }

        Button {
            viewModel.navigate(.discoverTags)
        } label: {
            Label(Strings.discoverTags, systemImage: "sparkle.magnifyingglass")
        }
    }

    func delete(at offsets: IndexSet) {
        // TODO: (wpsidebar) implement
    }
}

private struct Strings {
    static let addTag = NSLocalizedString("reader.sidebar.section.tags.addTag", value: "Add tag", comment: "Reader sidebar button")
    static let discoverTags = NSLocalizedString("reader.sidebar.section.tags.discoverTags", value: "Discover More Tags", comment: "Reader sidebar button")
}
