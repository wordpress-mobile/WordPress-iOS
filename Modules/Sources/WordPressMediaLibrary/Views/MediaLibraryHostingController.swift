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
        tracker: any MediaTracker,
        uploader: MediaUploader,
        urlOpener: any MediaDetailURLOpener,
        shareService: any MediaDetailShareService,
        navigator: any MediaDetailNavigator,
        capabilities: MediaLibraryCapabilities,
        externalPickerOptions: [ExternalMediaPickerOption] = []
    ) -> UIViewController {
        let hostContext = MediaLibraryHostContext()
        let view = MediaLibraryContainerView(
            client: client,
            tracker: tracker,
            uploader: uploader,
            urlOpener: urlOpener,
            shareService: shareService,
            navigator: navigator,
            capabilities: capabilities,
            externalPickerOptions: externalPickerOptions,
            hostContext: hostContext
        )
        let host = HostingController(rootView: view, context: hostContext)
        host.navigationItem.largeTitleDisplayMode = .never
        return host
    }
}

/// Live, containment-derived facts about the screen's UIKit hosting that the
/// SwiftUI hierarchy can't observe on its own. Written by `HostingController`
/// from real containment at appearance time, read by `MediaLibraryView`.
final class MediaLibraryHostContext: ObservableObject {
    /// When the screen sits above a bottom tab bar (e.g. Jetpack's tab bar,
    /// or the iPad split view's compact column), the search field minimizes
    /// into a toolbar button so it doesn't stack a second bar at the bottom
    /// of the screen. Without one it stays a full-width search bar.
    @Published var prefersMinimizedSearchBar = false
    /// Invoked when the screen is popped from its navigation controller (a
    /// real pop, not a tab switch). Tears down long-lived screen state such
    /// as selection mode and its in-flight bulk share.
    var handleDidPop: (() -> Void)?
}

private final class HostingController: UIHostingController<MediaLibraryContainerView> {
    private let context: MediaLibraryHostContext

    init(rootView: MediaLibraryContainerView, context: MediaLibraryHostContext) {
        self.context = context
        super.init(rootView: rootView)
        // Containment can change without a disappear/appear cycle when an
        // iPad window is resized across the compact boundary; re-derive on
        // size-class changes too.
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: HostingController, _) in
            self.updateSearchBarPreference()
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSearchBarPreference()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            context.handleDidPop?()
        }
    }

    private func updateSearchBarPreference() {
        context.prefersMinimizedSearchBar = (tabBarController != nil)
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
    let uploader: MediaUploader
    let urlOpener: any MediaDetailURLOpener
    let shareService: any MediaDetailShareService
    let navigator: any MediaDetailNavigator
    let capabilities: MediaLibraryCapabilities
    let externalPickerOptions: [ExternalMediaPickerOption]
    let hostContext: MediaLibraryHostContext

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
                    tracker: tracker,
                    externalPickerOptions: externalPickerOptions,
                    hostContext: hostContext
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
                let viewModel = MediaLibraryViewModel(
                    service: service,
                    client: client,
                    tracker: tracker,
                    uploader: uploader,
                    urlOpener: urlOpener,
                    shareService: shareService,
                    navigator: navigator,
                    capabilities: capabilities
                )
                // Popping the screen ends selection mode, which also cancels
                // an in-flight bulk share and releases its payload; nothing
                // else references the leaving screen's selection state.
                hostContext.handleDidPop = { [weak viewModel] in
                    viewModel?.exitSelectionMode()
                }
                resolved = Resolved(viewModel: viewModel, service: service)
            } catch {
                self.error = error
            }
        }
    }
}
