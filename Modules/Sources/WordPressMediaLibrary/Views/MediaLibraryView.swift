import DesignSystem
import SwiftUI
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

/// Container for the Media Library screen. Holds the library view model (kept
/// alive across search so clearing the field restores the library without a
/// refetch), owns the kind filter toolbar, the aspect-ratio toggle, and the
/// search field, and switches between the library grid and the search results.
struct MediaLibraryView: View {
    @ObservedObject var viewModel: MediaLibraryViewModel
    let service: WpService
    let client: WordPressClient
    let tracker: any MediaTracker

    @State private var searchText = ""
    @State private var isAspectRatioMode = AspectRatioPreference.load()
    /// Incremented by the Retry button so its `.task(id:)` re-fires; the initial
    /// value 0 is ignored so we don't double-load on appearance.
    @State private var retryToken = 0

    var body: some View {
        ZStack {
            if searchText.isEmpty {
                MediaGridView(items: viewModel.displayItems, isAspectRatioMode: isAspectRatioMode)
                    .refreshable { await viewModel.refresh() }
                    .overlay { libraryOverlay }
            } else {
                MediaLibrarySearchView(
                    service: service,
                    client: client,
                    tracker: tracker,
                    searchText: $searchText,
                    isAspectRatioMode: isAspectRatioMode
                )
            }
        }
        // The library load/observe tasks live on the always-present container,
        // not inside the `searchText.isEmpty` branch, so toggling search does
        // not tear them down and re-fire a full reload.
        .task { tracker.track(.mediaLibraryOpened) }
        .task { await viewModel.load() }
        .task { await viewModel.observe() }
        .task(id: retryToken) {
            guard retryToken > 0 else { return }
            await viewModel.refresh()
        }
        .navigationTitle(Strings.title)
        .searchable(text: $searchText, prompt: Strings.searchPrompt)
        .minimizedSearchToolbarBehavior()
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .toolbar { filterMenu }
    }

    @ToolbarContentBuilder private var filterMenu: some ToolbarContent {
        if searchText.isEmpty {
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
                            isAspectRatioMode.toggle()
                            AspectRatioPreference.save(isAspectRatioMode)
                            tracker.track(.mediaLibraryGridModeToggled(isAspectRatio: isAspectRatioMode))
                        } label: {
                            Label(
                                isAspectRatioMode ? Strings.squareGrid : Strings.aspectRatioGrid,
                                systemImage: isAspectRatioMode
                                    ? "rectangle.arrowtriangle.2.outward"
                                    : "rectangle.arrowtriangle.2.inward"
                            )
                        }
                    }
                } label: {
                    // Switch to the filled variant in the app accent color while
                    // a kind filter is active so the toolbar shows the library is
                    // filtered (the default toolbar tint renders black here).
                    if viewModel.kind == nil {
                        Image(systemName: "line.3.horizontal.decrease")
                    } else {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
    }

    @ViewBuilder private func filterButton(for kind: MediaKind?) -> some View {
        let title = kind?.title ?? Strings.filterAll
        let isSelected = kind == viewModel.kind
        Button {
            viewModel.setKind(kind)
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

    @ViewBuilder private var libraryOverlay: some View {
        if viewModel.shouldDisplayInitialLoading {
            ProgressView()
        } else if let error = viewModel.errorToDisplay() {
            errorView(error)
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

private extension View {
    /// Collapses the `.searchable` field into a navigation-bar button that
    /// expands on tap, matching the legacy Media screen. The `.minimize`
    /// behavior is iOS 26+, so this is a no-op on earlier versions.
    @ViewBuilder
    func minimizedSearchToolbarBehavior() -> some View {
        if #available(iOS 26, *) {
            searchToolbarBehavior(.minimize)
        } else {
            self
        }
    }
}
