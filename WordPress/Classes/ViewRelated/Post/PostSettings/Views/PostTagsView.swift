import SwiftUI
import Combine
import WordPressUI
import WordPressKit
import WordPressData
import WordPressAPI
import WordPressCore

struct PostTagsView: View {
    @StateObject var viewModel: TagsViewModel

    @State private var isKeyboardPresented = false

    /// - note: The tags are encoded as a comma-separate list.
    init(blog: Blog, selectedTags: String?, onSelectionChanged: @escaping (String) -> Void) {
        let viewModel = TagsViewModel(blog: blog, selectedTags: selectedTags, mode: .selection(onSelectedTagsChanged: { tags in
            onSelectionChanged(tags)
        }))
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    /// - note: The tags are encoded as a comma-separate list.
    init(blog: Blog, client: WordPressClient, taxonomy: SiteTaxonomy, selectedTerms: String? = nil, onSelectionChanged: @escaping (String) -> Void) {
        let viewModel = TagsViewModel(blog: blog, client: client, taxonomy: taxonomy, selectedTerms: selectedTerms, mode: .selection(onSelectedTagsChanged: { tags in
            onSelectionChanged(tags)
        }))
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { proxy in
                ScrollView {
                    SelectedTagsView(viewModel: viewModel)
                }
                .onChange(of: viewModel.selectedTags) { old, new in
                    if new.count == old.count + 1, let tag = new.last {
                        withAnimation {
                            proxy.scrollTo(tag)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                addTagsView
                    .frame(height: tagPickerHeight(in: proxy))
            }
        }
        .onReceive(keyboardPublisher) { isPresented in
            withAnimation(.smooth) {
                isKeyboardPresented = isPresented
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .interactiveDismissDisabled() // Prevent accidental screen dismissals when dismissing keyboard
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .onAppear {
            viewModel.onAppear()
        }
        .navigationTitle(viewModel.labels.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tagPickerHeight(in proxy: GeometryProxy) -> CGFloat {
        if isKeyboardPresented {
            return max(86, proxy.size.height - 86)
        }
        // When keyboard is dismissed, show more of the tags
        return proxy.size.height * 0.66
    }

    @ViewBuilder
    private var addTagsView: some View {
        let view = VStack(spacing: 0) {
            textField
                .padding(.horizontal)
                .padding(.top)
            if !viewModel.searchText.isEmpty {
                DataViewSearchView(
                    searchText: viewModel.searchText,
                    delay: viewModel.isLocalSearchEnabled ? nil : .milliseconds(330),
                    search: viewModel.search
                ) { response in
                    TagsPaginatedForEach(response: response, viewModel: viewModel)
                }
                .emptyStateViewHiddden()
            } else {
                List {
                    if let response = viewModel.response {
                        TagsPaginatedForEach(response: response, viewModel: viewModel)
                    }
                }
                .listStyle(.plain)
                .environment(\.defaultMinListRowHeight, 40)
            }
        }
        if #available(iOS 26, *) {
            view
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .padding(8)
                .padding(.bottom, -20) // Go under the keyboard
        } else {
            view
                .background(Material.regular)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .padding(8)
                .padding(.bottom, -20) // Go under the keyboard
        }
    }

    private var textField: some View {
        HStack {
            // We want to keep the focus on text field, after tapping the return key, which is not supported
            // by `SwiftUI.TextField`.
            AddTagsTextField(
                placeholder: Strings.searchPlaceholder(viewModel.localizedTaxonomyName),
                text: $viewModel.searchText,
                onSubmit: addTag
            )
            .onChange(of: viewModel.searchText) { (_, newValue) in
                handleTextChange(newValue)
            }

            if !viewModel.searchText.trim().isEmpty {
                Button(action: addTag) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Strings.addTag(viewModel.localizedTaxonomyName))
            }
        }
        .textFieldStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                            withAnimation(.spring) {
                                viewModel.removeSelectedTag(tagName)
                            }
                        }
                        .tag(tagName)
                    }
                }
                .padding(.horizontal)
            } else {
                Text(Strings.noTagsSelected(viewModel.localizedTaxonomyName))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
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
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(1)

            Image(systemName: "xmark")
                .foregroundColor(.secondary.opacity(0.75))
                .font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.secondarySystemBackground).opacity(0.75))
        .clipShape(Capsule())
        .onTapGesture(perform: onRemove)
    }
}

private struct AddTagsTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.autocapitalizationType = .none
        textField.returnKeyType = .default
        textField.accessibilityIdentifier = "add-tags"
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange), for: .editingChanged)

        // Ideally, we should bind the focus state of `textField` with `TagsView.isTextFieldFocused`, but I couldn't
        // get that working. So here, we always keep the text field on focused, which is the same as the old tags list.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800)) {
            textField.becomeFirstResponder()
        }

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != text {
            textField.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(view: self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        let view: AddTagsTextField

        init(view: AddTagsTextField) {
            self.view = view
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            let text = textField.text ?? ""
            if self.view.text != text {
                self.view.text = text
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            view.onSubmit()
            self.view.text = ""
            textField.text = ""
            return false
        }
    }
}

private extension View {
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers
            .Merge(
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillShowNotification)
                    .map { _ in true },
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { _ in false })
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

private enum Strings {
    static func searchPlaceholder(_ taxonomyName: String) -> String {
        let format = NSLocalizedString(
            "postTags.searchOrAdd.placeholder",
            value: "Search or add %1$@",
            comment: "Placeholder text for the taxonomy search field. %1$@ is the taxonomy name (e.g., 'tags', 'categories')."
        )
        return String.localizedStringWithFormat(format, taxonomyName.lowercased())
    }

    static func noTagsSelected(_ taxonomyName: String) -> String {
        let format = NSLocalizedString(
            "postTags.selectionEmpty",
            value: "No %1$@ are selected",
            comment: "Message shown when no taxonomy terms are selected. %1$@ is the taxonomy name (e.g., 'tags', 'categories')."
        )
        return String.localizedStringWithFormat(format, taxonomyName.lowercased())
    }

    static func addTag(_ taxonomyName: String) -> String {
        let format = NSLocalizedString(
            "postTags.addTag",
            value: "Add %1$@",
            comment: "Button to add a new taxonomy term. %1$@ is the taxonomy name (e.g., 'tags', 'categories')."
        )
        return String.localizedStringWithFormat(format, taxonomyName.lowercased())
    }
}
