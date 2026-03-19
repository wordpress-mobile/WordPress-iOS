import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressData

struct CustomPostParentPagePicker: View {
    @StateObject private var listViewModel: CustomPostListViewModel
    private let blog: Blog
    private let service: WpService
    private let details: PostTypeDetailsWithEditContext
    private let client: WordPressClient
    private let currentPostID: Int?
    private let currentParentID: Int?
    private let onSelection: (Int?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var finalSearchText = ""

    init(
        client: WordPressClient,
        service: WpService,
        details: PostTypeDetailsWithEditContext,
        blog: Blog,
        currentPostID: Int?,
        currentParentID: Int?,
        onSelection: @escaping (Int?) -> Void
    ) {
        self.blog = blog
        self.service = service
        self.details = details
        self.client = client
        self.currentPostID = currentPostID
        self.currentParentID = currentParentID
        self.onSelection = onSelection

        let excludeCurrentPost = currentPostID.map { postID in
            let id = Int64(postID)
            return #Predicate<CustomPostCollectionItem> { $0.id == id }
        }
        _listViewModel = StateObject(wrappedValue: CustomPostListViewModel(
            client: client,
            service: service,
            details: details,
            filter: CustomPostListFilter(statuses: [.publish]),
            blog: blog,
            exclude: excludeCurrentPost
        ))
    }

    var body: some View {
        ZStack {
            if finalSearchText.isEmpty {
                publishedList
            } else {
                searchResultsList
            }
        }
        .searchable(text: $searchText)
        .task(id: searchText) {
            do {
                try await Task.sleep(for: .milliseconds(100))
                finalSearchText = searchText
            } catch {
                // Do nothing.
            }
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectedPostID: Int64? {
        currentParentID.map { Int64($0) }
    }

    private var excludeCurrentPost: Predicate<CustomPostCollectionItem>? {
        currentPostID.map { postID in
            let id = Int64(postID)
            return #Predicate<CustomPostCollectionItem> { $0.id == id }
        }
    }

    private var publishedList: some View {
        CustomPostListView(
            viewModel: listViewModel,
            details: details,
            client: client,
            showsPostActions: false,
            selectedPostID: selectedPostID,
            onSelectPost: didSelectPost,
            header: {
                topLevelRow
            }
        )
    }

    private var searchResultsList: some View {
        CustomPostListView(
            viewModel: CustomPostListViewModel(
                client: client,
                service: service,
                details: details,
                filter: .search(input: finalSearchText),
                blog: blog,
                exclude: excludeCurrentPost
            ),
            details: details,
            client: client,
            showsPostActions: false,
            selectedPostID: selectedPostID,
            onSelectPost: didSelectPost
        )
    }

    private func didSelectPost(_ post: AnyPostWithEditContext) {
        onSelection(Int(post.id))
        dismiss()
    }

    private var topLevelRow: some View {
        VStack(spacing: 0) {
            Button {
                onSelection(nil)
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.topLevel)
                            .foregroundStyle(.primary)
                        Text(Strings.topLevelDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if currentParentID == nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            Divider()
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "customPostParentPicker.title",
        value: "Parent Page",
        comment: "Title for the parent page picker screen for custom post types"
    )

    static let topLevel = NSLocalizedString(
        "customPostParentPicker.topLevel",
        value: "Top level",
        comment: "Option to set a post as top level (no parent)"
    )

    static let topLevelDescription = NSLocalizedString(
        "customPostParentPicker.topLevel.description",
        value: "No parent page",
        comment: "Description for the top level option in the parent page picker, indicating this page will have no parent"
    )
}
