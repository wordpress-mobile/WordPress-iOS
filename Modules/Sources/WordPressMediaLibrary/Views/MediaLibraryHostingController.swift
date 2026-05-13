import SwiftUI
import UIKit
import WordPressCore

public enum MediaLibraryHostingController {
    /// Module-side factory. Constructs the ViewModel from a resolved
    /// WordPressClient and wraps it in a UIHostingController. The Blog gate
    /// and WordPressClient construction live in the app target — see
    /// `WordPress/Classes/ViewRelated/Media/MediaLibraryRouting.swift`.
    @MainActor
    public static func make(
        client: WordPressClient,
        tracker: any MediaTracker
    ) -> UIViewController {
        let viewModel = MediaLibraryViewModel(client: client, tracker: tracker)
        let view = MediaLibraryView(viewModel: viewModel, tracker: tracker)
        let host = UIHostingController(rootView: view)
        host.navigationItem.largeTitleDisplayMode = .never
        return host
    }
}
