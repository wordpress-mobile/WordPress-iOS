import SwiftUI

struct MediaLibraryView: View {
    @ObservedObject var viewModel: MediaLibraryViewModel
    let tracker: any MediaTracker

    @State private var searchText: String = ""
    /// Incremented by the Retry button. A `.task(id: retryToken)` modifier
    /// listens for changes; the initial value 0 is ignored so we don't
    /// re-fire refresh on appearance (the filter-driven `.task(id:)` already
    /// covers initial load). Switching to a SwiftUI-owned token keeps Retry
    /// inside the same cancellation lifecycle as filter / search / observer
    /// tasks — an unstructured `Task { … }` from the button action would
    /// outlive view dismantle.
    @State private var retryToken: Int = 0

    var body: some View {
        GeometryReader { proxy in
            let layout = MediaGridLayoutMath(
                availableWidth: proxy.size.width,
                isAspectRatioMode: viewModel.isAspectRatioModeEnabled
            )
            ScrollView {
                LazyVGrid(columns: layout.columns, spacing: layout.spacing) {
                    ForEach(viewModel.items) { item in
                        MediaGridCell(
                            item: item,
                            isAspectRatioMode: viewModel.isAspectRatioModeEnabled
                        )
                        // Cell-scoped pagination trigger. SwiftUI cancels
                        // this task on cell disappear AND on view dismantle.
                        .task(id: item.id) {
                            await viewModel.loadNextPageIfNeeded(after: item)
                        }
                    }
                }
                // V1 parity: top inset matches the spacing.
                .padding(.top, layout.spacing)
                .animation(.default, value: viewModel.isAspectRatioModeEnabled)
            }
            .refreshable { await viewModel.refresh(pullToRefresh: true) }
        }
        .task { tracker.track(.mediaLibraryOpened) }
        .task(id: viewModel.filter) { await viewModel.refresh() }
        .task(id: viewModel.filter) { await viewModel.handleDataChanges() }
        .task(id: searchText) {
            // SwiftUI cancels this on every searchText change and on
            // view dismantle. try-await propagates cancellation so the
            // setFilter hop never fires after dismissal or mid-typing.
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                return
            }
            viewModel.setFilter(viewModel.filter.with(search: searchText))
        }
        .task(id: retryToken) {
            // Skip the initial value — first appearance is driven by the
            // `.task(id: viewModel.filter)` modifier above.
            guard retryToken > 0 else { return }
            await viewModel.refresh()
        }
        .navigationTitle(Strings.title)
        .searchable(text: $searchText, prompt: Strings.searchPrompt)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .toolbar { filterMenu }
        .overlay { contentOverlay }
    }

    @ToolbarContentBuilder private var filterMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section {
                    filterButton(for: nil)
                    ForEach(MediaKind.allCases, id: \.self) { kind in
                        filterButton(for: kind)
                    }
                }
                Section {
                    Button {
                        viewModel.isAspectRatioModeEnabled.toggle()
                    } label: {
                        Label(
                            viewModel.isAspectRatioModeEnabled ? Strings.squareGrid : Strings.aspectRatioGrid,
                            systemImage: viewModel.isAspectRatioModeEnabled
                                ? "rectangle.arrowtriangle.2.outward"
                                : "rectangle.arrowtriangle.2.inward"
                        )
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }
        }
    }

    @ViewBuilder private func filterButton(for kind: MediaKind?) -> some View {
        let title = kind?.title ?? Strings.filterAll
        let isSelected = kind == viewModel.filter.kind
        Button {
            viewModel.setFilter(viewModel.filter.with(kind: kind))
        } label: {
            if isSelected {
                Label(title, systemImage: "checkmark")
            } else if let systemImage = kind?.systemImageName {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
    }

    @ViewBuilder private var contentOverlay: some View {
        if viewModel.shouldDisplayInitialLoading {
            ProgressView()
        } else if let error = viewModel.errorToDisplay() {
            errorView(error)
        } else if viewModel.shouldDisplaySearchEmpty {
            ContentUnavailableView.search(text: viewModel.filter.search)
        } else if viewModel.shouldDisplayFilterEmpty {
            ContentUnavailableView(Strings.emptyFiltered, systemImage: "photo.on.rectangle")
        } else if viewModel.shouldDisplayEmpty {
            ContentUnavailableView(Strings.empty, systemImage: "photo.on.rectangle")
        }
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(Strings.errorRetry) {
                retryToken += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
