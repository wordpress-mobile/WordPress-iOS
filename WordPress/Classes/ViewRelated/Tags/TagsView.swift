import SwiftUI
import WordPressUI
import WordPressKit
import WordPressData

struct TagsView: View {
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SelectedTagsView(viewModel: viewModel)

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
                    TagRowView(tag: tag, viewModel: viewModel)
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
        Button("Add a new tag: \(viewModel.searchText)", systemImage: "plus") {
            viewModel.addNewTag(named: viewModel.searchText.trim())
        }
        .padding([.horizontal, .top])
        DataViewSearchView(
            searchText: viewModel.searchText,
            search: viewModel.search
        ) { response in
            DataViewPaginatedForEach(response: response) { tag in
                TagRowView(tag: tag, viewModel: viewModel)
            }
        }
    }
}

private struct TagsPaginatedForEach: View {
    @ObservedObject var response: TagsPaginatedResponse
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        DataViewPaginatedForEach(response: response) { tag in
            TagRowView(tag: tag, viewModel: viewModel)
        }
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeRows(proposal: proposal, subviews: subviews)
        let width = proposal.width ?? 0
        let height = rows.reduce(0) { result, row in
            let rowHeight = row.map { $0.dimensions(in: .unspecified).height }.max() ?? 0
            return result + rowHeight + (result > 0 ? spacing : 0)
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.dimensions(in: .unspecified).height }.max() ?? 0

            for subview in row {
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(subview.sizeThatFits(.unspecified)))
                x += subview.dimensions(in: .unspecified).width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func arrangeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let availableWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = []
        var currentRow: [LayoutSubviews.Element] = []
        var currentWidth: CGFloat = 0

        for subview in subviews {
            let subviewWidth = subview.dimensions(in: .unspecified).width

            if currentWidth + subviewWidth <= availableWidth || currentRow.isEmpty {
                currentRow.append(subview)
                currentWidth += subviewWidth + (currentRow.count > 1 ? spacing : 0)
            } else {
                rows.append(currentRow)
                currentRow = [subview]
                currentWidth = subviewWidth
            }
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}

private struct SelectedTagsView: View {
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !viewModel.selectedTags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.selectedTags, id: \.self) { tagName in
                        SelectedTag(tagName: tagName) {
                            viewModel.removeSelectedTag(tagName)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                Text(Strings.noTagsSelected)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

private struct SelectedTag: View {
    let tagName: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tagName)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(UIColor.systemGray5))
        .clipShape(Capsule())
    }
}

private struct TagRowView: View {
    let tag: RemotePostTag
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        HStack {
            Text(tag.name ?? "")
                .font(.body)

            Spacer()

            if viewModel.isSelected(tag) {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.toggleSelection(for: tag)
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

    static let noTagsSelected = NSLocalizedString(
        "tags.selected.empty",
        value: "No tags are selected",
        comment: "Message shown when no tags are selected"
    )
}

class TagsViewController: UIHostingController<TagsView> {
    let viewModel: TagsViewModel

    init(blog: Blog, selectedTags: String? = nil, onSelectedTagsChanged: ((String) -> Void)? = nil) {
        viewModel = TagsViewModel(blog: blog, selectedTags: selectedTags, onSelectedTagsChanged: onSelectedTagsChanged)
        super.init(rootView: .init(viewModel: viewModel))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
