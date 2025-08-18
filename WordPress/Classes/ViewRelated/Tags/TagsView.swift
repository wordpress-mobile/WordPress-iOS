import SwiftUI
import WordPressUI
import WordPressKit
import WordPressData

struct TagsView: View {
    @ObservedObject var viewModel: TagsViewModel
    @FocusState private var isTextFieldFocused: Bool

    @State private var showingAddTagModal = false

    var allowAddingTagsFromTextField: Bool {
        if case .selection = viewModel.mode {
            return true
        }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if case .selection = viewModel.mode {
                SelectedTagsView(viewModel: viewModel)
            }

            searchField

            if !viewModel.searchText.isEmpty {
                TagsSearchView(viewModel: viewModel, isTextFieldFocused: $isTextFieldFocused)
            } else {
                TagsListView(viewModel: viewModel, isTextFieldFocused: $isTextFieldFocused)
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
        .navigationTitle(Strings.title)
        .toolbar {
            if case .browse = viewModel.mode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTagModal = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTagModal) {
            NavigationView {
                EditTagView(tag: nil, tagsService: viewModel.tagsService)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(SharedStrings.Button.cancel) {
                                showingAddTagModal = false
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var searchField: some View {
        HStack {
            let placeholder = allowAddingTagsFromTextField ? Strings.searchOrAddTagsPlaceholder : Strings.searchPlaceholder
            let textField = TextField(placeholder, text: $viewModel.searchText)
                .focused($isTextFieldFocused)
                .textInputAutocapitalization(.never)
                .submitLabel(.return)
                .accessibilityIdentifier("add-tags")

            if allowAddingTagsFromTextField {
                textField
                    .onSubmit(addTag)
                    .onChange(of: viewModel.searchText) { newValue in
                        handleTextChange(newValue)
                    }
            } else {
                textField
            }

            if allowAddingTagsFromTextField, !viewModel.searchText.trim().isEmpty {
                Button(action: addTag) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Strings.addTag(viewModel.searchText.trim()))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func handleTextChange(_ newValue: String) {
        let components = newValue.components(separatedBy: ",")
        guard components.count >= 2 else { return }

        // Add all text before a comma as new tags.
        for index in 0..<components.count - 1 {
            let tagToAdd = components[index].trim()
            if !tagToAdd.isEmpty {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.addNewTag(named: tagToAdd)
                }
            }
        }

        // Keep the last component as the remaining text in the field
        let remainingText = components.last?.trim() ?? ""
        viewModel.searchText = remainingText
    }

    private func addTag() {
        let trimmedText = viewModel.searchText.trim()
        if !trimmedText.isEmpty {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.addNewTag(named: trimmedText)
            }
            viewModel.searchText = ""
        }
    }
}

private struct TagsListView: View {
    @ObservedObject var viewModel: TagsViewModel
    @FocusState.Binding var isTextFieldFocused: Bool

    var body: some View {
        List {
            if let response = viewModel.response {
                TagsPaginatedForEach(response: response, viewModel: viewModel)
            }
        }
        .listStyle(.plain)
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    isTextFieldFocused = false
                }
        )
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
    @FocusState.Binding var isTextFieldFocused: Bool

    var body: some View {
        DataViewSearchView(
            searchText: viewModel.searchText,
            search: viewModel.search
        ) { response in
            TagsPaginatedForEach(response: response, viewModel: viewModel)
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    isTextFieldFocused = false
                }
        )
        .padding(.top, 16)
    }
}

private struct TagsPaginatedForEach: View {
    @ObservedObject var response: TagsPaginatedResponse
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        DataViewPaginatedForEach(response: response) { tag in
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
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.removeSelectedTag(tagName)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                Text(Strings.noTagsSelected)
                    .font(.callout)
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
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)

            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(Capsule())
        .onTapGesture(perform: onRemove)
    }
}

private struct TagRowView: View {
    let tag: RemotePostTag
    @ObservedObject var viewModel: TagsViewModel

    var body: some View {
        Group {
            if case .browse = viewModel.mode {
                NavigationLink(destination: EditTagView(tag: tag, tagsService: viewModel.tagsService)) {
                    TagRowContent(tag: tag, showPostCount: true, isSelected: false)
                }
            } else {
                TagRowContent(tag: tag, showPostCount: false, isSelected: viewModel.isSelected(tag))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        switch viewModel.mode {
                        case .selection:
                            viewModel.toggleSelection(for: tag)
                        case .browse:
                            break
                        }
                    }
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
            } else if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
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

    static let noTagsSelected = NSLocalizedString(
        "tags.selected.empty",
        value: "No tags are selected",
        comment: "Message shown when no tags are selected"
    )

    static let searchPlaceholder = NSLocalizedString(
        "tags.search.placeholder",
        value: "Search tags",
        comment: "Placeholder text for the tag search field"
    )

    static let searchOrAddTagsPlaceholder = NSLocalizedString(
        "tags.search.placeholder",
        value: "Search or add tags",
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

    static func addTag(_ tagName: String) -> String {
        let template = NSLocalizedString(
            "tags.add.button",
            value: "Add tag: %1$@",
            comment: "Button to add a new tag. %1$@ is the tag name."
        )
        return String.localizedStringWithFormat(template, tagName)
    }
}

class TagsViewController: UIHostingController<TagsView> {
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
