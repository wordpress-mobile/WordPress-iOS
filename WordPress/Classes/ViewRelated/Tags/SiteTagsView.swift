import SwiftUI
import WordPressUI
import WordPressKit
import WordPressData

struct SiteTagsView: View {
    @ObservedObject var viewModel: TagsViewModel

    @State private var isShowingAddTagView = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.searchText.isEmpty {
                TagsSearchView(viewModel: viewModel)
            } else {
                TagsListView(viewModel: viewModel)
            }
        }
        .navigationTitle(Strings.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddTagView = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: Strings.searchPlaceholder)
        .sheet(isPresented: $isShowingAddTagView) {
            NavigationView {
                EditTagView(tag: nil, tagsService: viewModel.tagsService)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(SharedStrings.Button.cancel) {
                                isShowingAddTagView = false
                            }
                        }
                    }
            }
        }
    }
}

private struct TagsListView: View {
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        List {
            if let response = viewModel.response {
                TagsPaginatedForEach(response: response, viewModel: viewModel)
            }
        }
        .listStyle(.plain)
        .overlay {
            if let response = viewModel.response {
                if response.isEmpty {
                    EmptyStateView(
                        Strings.empty,
                        systemImage: "tag",
                        description: Strings.emptyDescription
                    )
                }
            } else if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                EmptyStateView.failure(error: error) {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

private struct TagsSearchView: View {
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        DataViewSearchView(searchText: viewModel.searchText, search: viewModel.search) { response in
            TagsPaginatedForEach(response: response, viewModel: viewModel)
        }
    }
}

struct TagsPaginatedForEach: View {
    @ObservedObject var response: TagsPaginatedResponse
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        DataViewPaginatedForEach(response: response, filter: viewModel.isNotSelected(_:)) { tag in
            TagRowView(tag: tag, viewModel: viewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .tagDeleted)) { notification in
            tagDeleted(userInfo: notification.userInfo)
        }
        .onReceive(NotificationCenter.default.publisher(for: .tagCreated)) { notification in
            tagCreated(userInfo: notification.userInfo)
        }
        .onReceive(NotificationCenter.default.publisher(for: .tagUpdated)) { notification in
            tagUpdated(userInfo: notification.userInfo)
        }
    }

    private func tagDeleted(userInfo: [AnyHashable: Any]?) {
        if let tagID = userInfo?[TagNotificationUserInfoKeys.tagID] as? NSNumber {
            response.deleteItem(withID: tagID.intValue)
        }
    }

    private func tagCreated(userInfo: [AnyHashable: Any]?) {
        if let tag = userInfo?[TagNotificationUserInfoKeys.tag] as? RemotePostTag {
            response.prepend([tag])
        }
    }

    private func tagUpdated(userInfo: [AnyHashable: Any]?) {
        if let tag = userInfo?[TagNotificationUserInfoKeys.tag] as? RemotePostTag {
            response.replace(tag)
        }
    }
}

private struct TagRowView: View {
    let tag: RemotePostTag
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        switch viewModel.mode {
        case .selection:
            TagRowContent(tag: tag, showPostCount: false, isSelected: viewModel.isSelected(tag))
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring) {
                        viewModel.toggleSelection(for: tag)
                    }
                }
                .listRowBackground(Color.clear)
        case .browse:
            NavigationLink(destination: EditTagView(tag: tag, tagsService: viewModel.tagsService)) {
                TagRowContent(tag: tag, showPostCount: true, isSelected: false)
            }
        }
    }
}

private struct TagRowContent: View {
    let tag: RemotePostTag
    let showPostCount: Bool
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(tag.name ?? "")
                .font(.body)

            Spacer()

            if showPostCount, let postCount = tag.postCount?.intValue, postCount > 0 {
                Text("\(postCount)")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "tags.title",
        value: "Tags",
        comment: "Title for the tags screen"
    )

    static let empty = NSLocalizedString(
        "tags.empty.title",
        value: "No Tags",
        comment: "Title for empty state when there are no tags"
    )

    static let emptyDescription = NSLocalizedString(
        "tags.empty.description",
        value: "Tags help organize your content and make it easier for readers to find related posts.",
        comment: "Description for empty state when there are no tags"
    )

    static let searchPlaceholder = NSLocalizedString(
        "tags.search.placeholder",
        value: "Search tags",
        comment: "Placeholder text for the tag search field"
    )

    static func removeTag(_ tagName: String) -> String {
        let template = NSLocalizedString(
            "tags.remove.button",
            value: "Remove %1$@",
            comment: "Button to remove a selected tag. %1$@ is the tag name."
        )
        return String.localizedStringWithFormat(template, tagName)
    }
}

class SiteTagsViewController: UIHostingController<SiteTagsView> {
    let viewModel: TagsViewModel

    init(blog: Blog, selectedTags: String? = nil, mode: TagsViewMode) {
        viewModel = TagsViewModel(blog: blog, selectedTags: selectedTags, mode: mode)
        super.init(rootView: .init(viewModel: viewModel))
    }

    convenience init(blog: Blog, selectedTags: String? = nil, onSelectedTagsChanged: ((String) -> Void)? = nil) {
        self.init(blog: blog, selectedTags: selectedTags, mode: .selection(onSelectedTagsChanged: onSelectedTagsChanged))
    }

    convenience init(blog: Blog) {
        self.init(blog: blog, mode: .browse)
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
