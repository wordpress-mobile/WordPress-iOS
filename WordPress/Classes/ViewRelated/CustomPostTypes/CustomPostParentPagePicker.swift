import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore
import WordPressData

struct CustomPostParentPagePicker: View {
    @StateObject private var listViewModel: CustomPostListViewModel
    private let details: PostTypeDetailsWithEditContext
    private let client: WordPressClient
    private let currentPostID: Int?
    private let currentParentID: Int?
    private let onSelection: (Int?) -> Void

    @Environment(\.dismiss) private var dismiss

    init(
        client: WordPressClient,
        service: WpService,
        details: PostTypeDetailsWithEditContext,
        blog: Blog,
        currentPostID: Int?,
        currentParentID: Int?,
        onSelection: @escaping (Int?) -> Void
    ) {
        self.details = details
        self.client = client
        self.currentPostID = currentPostID
        self.currentParentID = currentParentID
        self.onSelection = onSelection

        _listViewModel = StateObject(wrappedValue: CustomPostListViewModel(
            client: client,
            service: service,
            details: details,
            filter: CustomPostListFilter(statuses: [.publish]),
            blog: blog
        ))
    }

    var body: some View {
        CustomPostListView(
            viewModel: listViewModel,
            details: details,
            client: client,
            showsPostActions: false,
            onSelectPost: { post in
                onSelection(Int(post.id))
                dismiss()
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
            dismiss()
        } label: {
            HStack {
                Text(Strings.topLevel)
                    .foregroundStyle(.primary)
                Spacer()
                if currentParentID == nil {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
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
}
