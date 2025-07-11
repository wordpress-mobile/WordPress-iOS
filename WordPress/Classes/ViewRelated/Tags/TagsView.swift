import SwiftUI
import WordPressUI
import WordPressKit
import WordPressData

struct TagsView: View {
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        Group {
            if !viewModel.searchText.isEmpty {
                TagsSearchView(viewModel: viewModel)
            } else {
                TagsListView(viewModel: viewModel)
            }
        }
        .navigationTitle(Strings.title)
        .searchable(text: $viewModel.searchText)
        .textInputAutocapitalization(.never)
    }
}

private struct TagsListView: View {
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        List {
            if let response = viewModel.response {
                DataViewPaginatedForEach(response: response) { tag in
                    TagRowView(tag: tag)
                }
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
        .refreshable {
            await viewModel.refresh()
        }
    }
}

private struct TagsSearchView: View {
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        DataViewSearchView(
            searchText: viewModel.searchText,
            search: viewModel.search
        ) { response in
            DataViewPaginatedForEach(response: response) { tag in
                TagRowView(tag: tag)
            }
        }
    }
}

private struct TagsPaginatedForEach: View {
    @ObservedObject var response: TagsPaginatedResponse

    var body: some View {
        DataViewPaginatedForEach(response: response) { tag in
            TagRowView(tag: tag)
        }
    }
}

private struct TagRowView: View {
    let tag: RemotePostTag

    var body: some View {
        Text(tag.name ?? "")
            .font(.body)
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
}

class TagsViewController: UIHostingController<TagsView> {
    let viewModel: TagsViewModel

    init(blog: Blog) {
        viewModel = TagsViewModel(blog: blog)
        super.init(rootView: .init(viewModel: viewModel))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
