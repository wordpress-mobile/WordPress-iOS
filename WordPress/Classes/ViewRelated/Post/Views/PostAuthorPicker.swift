import SwiftUI
import WordPressData
import WordPressUI
import WordPressShared

struct PostAuthorPicker: View {
    @StateObject private var viewModel: PostAuthorPickerViewModel
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    init(blog: Blog, currentAuthorID: Int?, onSelection: @escaping (PostAuthorPickerViewModel.AuthorItem) -> Void) {
        _viewModel = StateObject(wrappedValue: PostAuthorPickerViewModel(blog: blog, currentAuthorID: currentAuthorID, onSelection: onSelection))
    }

    /// Convenience initializer that extracts blog and authorID from post
    init(post: AbstractPost, onSelection: @escaping (PostAuthorPickerViewModel.AuthorItem) -> Void) {
        self.init(blog: post.blog, currentAuthorID: post.authorID?.intValue, onSelection: onSelection)
    }

    var body: some View {
        List {
            ForEach(filteredAuthors) { author in
                Button {
                    viewModel.selectAuthor(author)
                    dismiss()
                } label: {
                    AuthorRow(author: author, isSelected: viewModel.isSelected(author))
                }
                .buttonStyle(.plain)
            }
        }
        .environment(\.defaultMinListRowHeight, 54)
        .listStyle(.plain)
        .searchable(text: $searchText)
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filteredAuthors: [PostAuthorPickerViewModel.AuthorItem] {
        if searchText.isEmpty {
            return viewModel.authors
        }
        return viewModel.authors.search(searchText) { author in
            // Combine display name and username for search
            var searchableText = author.displayName
            if let username = author.username {
                searchableText += " @\(username)"
            }
            return searchableText
        }
    }
}

private struct AuthorRow: View {
    let author: PostAuthorPickerViewModel.AuthorItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(style: .single(author.avatarURL), diameter: 36)

            VStack(alignment: .leading) {
                Text(author.displayName)
                    .font(.callout.weight(.medium))

                if let username = author.username {
                    Text("@\(username)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .lineLimit(1)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .fontWeight(.medium)
            }
        }
        .contentShape(Rectangle())
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "postAuthorPicker.title",
        value: "Author",
        comment: "Title for the post author selection screen"
    )
}
