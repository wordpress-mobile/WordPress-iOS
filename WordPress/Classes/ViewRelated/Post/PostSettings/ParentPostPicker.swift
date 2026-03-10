import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressData

/// A picker for selecting a parent post for hierarchical custom post types.
///
/// Wraps `CustomPostListView` filtered to published posts of the same type,
/// with a "Top level" option and checkmark selection state.
struct ParentPostPicker: View {
    let blog: Blog
    let client: WordPressClient
    let service: WpService
    let details: PostTypeDetailsWithEditContext
    let excludePostID: Int64?
    let selectedParentID: Int?
    let onSelection: (Int?) -> Void

    @StateObject private var viewModel: CustomPostListViewModel

    private var excludePostIDs: Set<Int64> {
        if let excludePostID {
            return [excludePostID]
        }
        return []
    }

    init(
        blog: Blog,
        client: WordPressClient,
        service: WpService,
        details: PostTypeDetailsWithEditContext,
        excludePostID: Int64?,
        selectedParentID: Int?,
        onSelection: @escaping (Int?) -> Void
    ) {
        self.blog = blog
        self.client = client
        self.service = service
        self.details = details
        self.excludePostID = excludePostID
        self.selectedParentID = selectedParentID
        self.onSelection = onSelection

        _viewModel = StateObject(wrappedValue: CustomPostListViewModel(
            client: client,
            service: service,
            details: details,
            filter: CustomPostListFilter(status: .publish),
            blog: blog
        ))
    }

    var body: some View {
        CustomPostListView(
            viewModel: viewModel,
            details: details,
            client: client,
            excludePostIDs: excludePostIDs,
            selectedPostID: selectedParentID.map { Int64($0) },
            onSelectPost: { post in
                onSelection(Int(post.id))
            },
            header: {
                topLevelRow
            }
        )
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var topLevelRow: some View {
        Button {
            onSelection(nil)
        } label: {
            HStack {
                Text(Strings.topLevel)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedParentID == nil {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "parentPostPicker.title",
        value: "Parent",
        comment: "Navigation title for the parent post picker screen"
    )
    static let topLevel = NSLocalizedString(
        "parentPostPicker.topLevel",
        value: "Top level",
        comment: "Option to set a post as top-level (no parent)"
    )
}
