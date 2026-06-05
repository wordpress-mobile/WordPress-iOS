import SwiftUI
import UIKit
import WordPressAPIInternal
import WordPressCore
import WordPressUI

public enum MediaLibraryHostingController {
    /// Module-side factory. Wraps a loading container in a UIHostingController.
    /// The container resolves `WpService` and builds the ViewModel. The Blog
    /// gate and WordPressClient construction live in the app target — see
    /// `WordPress/Classes/ViewRelated/Media/MediaLibraryRouting.swift`.
    @MainActor
    public static func make(
        client: WordPressClient,
        tracker: any MediaTracker
    ) -> UIViewController {
        let view = MediaLibraryContainerView(client: client, tracker: tracker)
        let host = UIHostingController(rootView: view)
        host.navigationItem.largeTitleDisplayMode = .never
        return host
    }
}

/// Resolves `WpService` from the actor-isolated `WordPressClient` before
/// constructing `MediaLibraryViewModel`, which needs the service synchronously.
/// The resolution is a single actor hop (no network), so the loading state is
/// effectively instantaneous; the error/retry path covers the rare case where
/// service creation throws. Both the resolved service and the library view
/// model are passed to `MediaLibraryView` so it can build search view models.
private struct MediaLibraryContainerView: View {
    let client: WordPressClient
    let tracker: any MediaTracker

    @State private var resolved: Resolved?
    @State private var error: Error?
    /// Bumped by Retry to re-fire the resolution `.task`.
    @State private var attempt = 0

    private struct Resolved {
        let viewModel: MediaLibraryViewModel
        let service: WpService
    }

    var body: some View {
        ZStack {
            if let resolved {
                MediaLibraryView(
                    viewModel: resolved.viewModel,
                    service: resolved.service,
                    client: client,
                    tracker: tracker
                )
            } else if let error {
                EmptyStateView.failure(error: error) {
                    self.error = nil
                    attempt += 1
                }
                .navigationTitle(Strings.title)
            }
        }
        .task(id: attempt) {
            guard resolved == nil else { return }
            do {
                let service = try await client.service
                resolved = Resolved(
                    viewModel: MediaLibraryViewModel(
                        service: service,
                        client: client,
                        tracker: tracker
                    ),
                    service: service
                )
            } catch {
                self.error = error
            }
        }
    }
}
