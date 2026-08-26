import SwiftUI
import UIKit
import WordPressAPI
import WordPressAPIInternal
import WordPressCore

/// Search wrapper. Debounces the query, then builds a search-filtered
/// `MediaLibraryViewModel` for the committed query. Each committed query gets a
/// fresh instance (via `.id(query)`), so the previous instance and its load
/// task are torn down and the latest query wins.
struct MediaLibrarySearchView: View {
    let service: WpService
    let client: WordPressClient
    let tracker: any MediaTracker
    @Binding var searchText: String
    let isAspectRatioMode: Bool
    let urlOpener: (any MediaDetailURLOpener)?
    let shareService: (any MediaDetailShareService)?
    let navigator: (any MediaDetailNavigator)?
    let capabilities: MediaLibraryCapabilities?

    /// The debounced, committed query. Empty until the first debounce fires.
    @State private var query = ""

    var body: some View {
        Group {
            if query.isEmpty {
                ProgressView()
            } else {
                MediaSearchResultsView(
                    query: query,
                    service: service,
                    client: client,
                    tracker: tracker,
                    isAspectRatioMode: isAspectRatioMode,
                    urlOpener: urlOpener,
                    shareService: shareService,
                    navigator: navigator,
                    capabilities: capabilities
                )
                .id(query)
            }
        }
        .task(id: searchText) {
            // SwiftUI cancels this on every searchText change and on view
            // dismantle. try-await propagates cancellation so a stale query is
            // never committed after the field changes again.
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                return
            }
            guard !searchText.isEmpty else { return }
            query = searchText
        }
    }
}

/// Owns the search view model for a single committed query. A fresh instance is
/// created per query (the parent keys it with `.id(query)`), so `@StateObject`
/// builds the view model exactly once per query and `load()` fires on appear.
private struct MediaSearchResultsView: View {
    let query: String
    let tracker: any MediaTracker
    let isAspectRatioMode: Bool
    @StateObject private var viewModel: MediaLibraryViewModel

    init(
        query: String,
        service: WpService,
        client: WordPressClient,
        tracker: any MediaTracker,
        isAspectRatioMode: Bool,
        urlOpener: (any MediaDetailURLOpener)?,
        shareService: (any MediaDetailShareService)?,
        navigator: (any MediaDetailNavigator)?,
        capabilities: MediaLibraryCapabilities?
    ) {
        self.query = query
        self.tracker = tracker
        self.isAspectRatioMode = isAspectRatioMode
        _viewModel = StateObject(
            wrappedValue: MediaLibraryViewModel(
                service: service,
                client: client,
                tracker: tracker,
                search: query,
                urlOpener: urlOpener,
                shareService: shareService,
                navigator: navigator,
                capabilities: capabilities
            )
        )
    }

    var body: some View {
        MediaGridView(items: viewModel.displayItems, isAspectRatioMode: isAspectRatioMode) { item in
            if viewModel.canOpenDetail(for: item) {
                Button {
                    pushDetail(for: item)
                } label: {
                    MediaGridCell(item: item, isAspectRatioMode: isAspectRatioMode)
                }
                .buttonStyle(.plain)
            } else {
                MediaGridCell(item: item, isAspectRatioMode: isAspectRatioMode)
            }
        }
        .refreshable { await viewModel.refresh() }
        .task {
            tracker.track(.mediaLibrarySearched(queryLength: query.count))
            await viewModel.load()
        }
        .task { await viewModel.observe() }
        .overlay { overlay }
    }

    /// Same UIKit-bridge push as `MediaLibraryView.pushDetail`. The pushed
    /// detail screen owns its view model and lives on the outer UIKit nav
    /// stack, so a query change tearing down this view's `@StateObject`
    /// cannot strand it.
    private func pushDetail(for item: MediaGridItem) {
        guard let detailVM = viewModel.makeDetailVM(for: item) else { return }
        let host = UIHostingController(rootView: MediaDetailView(viewModel: detailVM))
        host.navigationItem.largeTitleDisplayMode = .never
        viewModel.detailNavigator?.push(host)
    }

    @ViewBuilder private var overlay: some View {
        if viewModel.shouldDisplayInitialLoading {
            ProgressView()
        } else if let error = viewModel.errorToDisplay() {
            ContentUnavailableView {
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
            }
        } else if viewModel.shouldDisplayEmpty {
            ContentUnavailableView.search(text: query)
        }
    }
}
