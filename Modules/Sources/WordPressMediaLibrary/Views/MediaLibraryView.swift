import SwiftUI

struct MediaLibraryView: View {
    @ObservedObject var viewModel: MediaLibraryViewModel
    let tracker: any MediaTracker

    var body: some View {
        List(viewModel.items) { item in
            MediaLibraryRow(item: item)
                .onAppear {
                    Task { await viewModel.loadNextPageIfNeeded(after: item) }
                }
        }
        .refreshable { await viewModel.pullToRefresh() }
        // Two .task modifiers run concurrently from view appearance. Refresh
        // is now deterministic on its own (calls loadItems directly after
        // network success), so the observer task is purely for subsequent
        // updates (browser-side edits etc.).
        .task { await viewModel.handleDataChanges() }
        .task {
            tracker.track(.mediaLibraryOpened)
            // performInitialLoad() owns isRefreshing across the entire
            // loadCachedItems + refresh sequence so the empty state can't
            // flash between them on cold-cache first open.
            await viewModel.performInitialLoad()
        }
        .navigationTitle(Strings.title)
        // Single overlay with explicit precedence — three separate overlays
        // could stack (e.g., empty + error both true after a failed cold-
        // cache refresh). Error wins, then empty, then loading.
        .overlay {
            if let error = viewModel.errorToDisplay() {
                errorView(error)
            } else if viewModel.shouldDisplayEmptyView {
                emptyView
            } else if viewModel.shouldDisplayInitialLoading {
                ProgressView()
            }
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            Strings.empty,
            systemImage: "photo.on.rectangle"
        )
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
                Task { await viewModel.refresh() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
