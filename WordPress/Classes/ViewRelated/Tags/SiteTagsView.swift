import SwiftUI
import WordPressUI
import WordPressKit
import WordPressData
import WordPressAPI

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
        .navigationTitle(viewModel.labels.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddTagView = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: viewModel.labels.searchPlaceholder)
        .sheet(isPresented: $isShowingAddTagView) {
            NavigationView {
                EditTagView(term: nil, taxonomy: viewModel.taxonomy, tagsService: viewModel.tagsService)
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
                        viewModel.labels.empty,
                        systemImage: "tag",
                        description: viewModel.labels.emptyDescription
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
            response.deleteItem(withID: tagID.int64Value)
        }
    }

    private func tagCreated(userInfo: [AnyHashable: Any]?) {
        if let term = userInfo?[TagNotificationUserInfoKeys.tag] as? AnyTermWithViewContext {
            response.prepend([term])
        }
    }

    private func tagUpdated(userInfo: [AnyHashable: Any]?) {
        if let term = userInfo?[TagNotificationUserInfoKeys.tag] as? AnyTermWithViewContext {
            response.replace(term)
        }
    }
}

private struct TagRowView: View {
    let tag: AnyTermWithViewContext
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
            NavigationLink(destination: EditTagView(term: tag, taxonomy: viewModel.taxonomy, tagsService: viewModel.tagsService)) {
                TagRowContent(tag: tag, showPostCount: true, isSelected: false)
            }
        }
    }
}

private struct TagRowContent: View {
    let tag: AnyTermWithViewContext
    let showPostCount: Bool
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(tag.name)
                .font(.body)

            Spacer()

            if showPostCount, tag.count > 0 {
                Text("\(tag.count)")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private enum Strings {
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

    init(blog: Blog) {
        viewModel = TagsViewModel(blog: blog, mode: .browse)
        super.init(rootView: .init(viewModel: viewModel))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
