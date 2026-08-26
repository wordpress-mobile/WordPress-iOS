import Combine
import SwiftUI
import UIKit
import WordPressData
import WordPressShared

/// Hosts the shared SwiftUI ``LikesListView`` for the Stats and Reader post-likes screens,
/// replacing the near-duplicate `StatsLikesListViewController` and
/// `ReaderDetailLikesListController`. It owns the navigation title, forwards the
/// per-feature analytics, and presents the user profile sheet on row taps.
final class LikesListHostViewController: UIHostingController<LikesListView> {

    /// Per-feature analytics identifiers, preserving the events emitted by the previous hosts.
    struct Configuration {
        let likeListOpenedSource: String
        let userProfileSheetShownSource: String
        let blogUrlPreviewedSource: String

        static let stats = Configuration(
            likeListOpenedSource: "stats_post_details",
            userProfileSheetShownSource: "stats_post_likes_list",
            blogUrlPreviewedSource: "stats_post_likes_list_user_profile"
        )

        static let reader = Configuration(
            likeListOpenedSource: "like_reader_list",
            userProfileSheetShownSource: "like_reader_list",
            blogUrlPreviewedSource: "reader_like_list_user_profile"
        )
    }

    private let viewModel: LikesListViewModel
    private let configuration: Configuration
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(viewModel: LikesListViewModel, configuration: Configuration) {
        self.viewModel = viewModel
        self.configuration = configuration
        super.init(rootView: LikesListView(viewModel: viewModel, onSelectUser: { _, _ in }))

        // `self` cannot be captured before `super.init`, so wire the callback now.
        rootView = LikesListView(viewModel: viewModel, onSelectUser: { [weak self] user, sourceRect in
            self?.displayUserProfile(user, sourceRect: sourceRect)
        })
    }

    /// Stats entry point.
    convenience init(siteID: NSNumber, postID: NSNumber, totalLikes: Int) {
        self.init(
            viewModel: LikesListViewModel(siteID: siteID, postID: postID, totalLikes: totalLikes),
            configuration: .stats
        )
    }

    /// Reader entry point. Fails when the post lacks the IDs needed to fetch likes.
    convenience init?(post: ReaderPost) {
        guard let viewModel = LikesListViewModel(post: post) else {
            return nil
        }
        self.init(viewModel: viewModel, configuration: .reader)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        // Keep the navigation title in sync with the total likes count.
        viewModel.$totalLikes
            .sink { [weak self] totalLikes in
                self?.updateTitle(totalLikes: totalLikes)
            }
            .store(in: &cancellables)

        WPAnalytics.track(.likeListOpened, properties: ["list_type": "post", "source": configuration.likeListOpenedSource])

        viewModel.loadMore()
    }

    // MARK: - Helpers

    private func updateTitle(totalLikes: Int) {
        let titleFormat = totalLikes == 1 ? TitleFormats.singular : TitleFormats.plural
        navigationItem.title = String(format: titleFormat, totalLikes)
    }

    private func displayUserProfile(_ user: LikeUser, sourceRect: CGRect) {
        let userProfileVC = UserProfileSheetViewController(user: user)
        userProfileVC.blogUrlPreviewedSource = configuration.blogUrlPreviewedSource
        userProfileVC.modalPresentationStyle = .popover
        userProfileVC.popoverPresentationController?.sourceView = view
        // Anchor the popover to the tapped row on iPad. `sourceRect` arrives in global
        // (window) coordinates; convert it into `view`'s space. On iPhone this adapts to a sheet.
        if view.window != nil, sourceRect != .zero {
            userProfileVC.popoverPresentationController?.sourceRect = view.convert(sourceRect, from: nil)
        }
        userProfileVC.popoverPresentationController?.adaptiveSheetPresentationController.prefersGrabberVisible = true
        userProfileVC.popoverPresentationController?.adaptiveSheetPresentationController.detents = [.medium()]
        present(userProfileVC, animated: true)

        WPAnalytics.track(.userProfileSheetShown, properties: ["source": configuration.userProfileSheetShownSource])
    }

    private enum TitleFormats {
        static let singular = NSLocalizedString(
            "%1$d Like",
            comment: "Singular format string for view title displaying the number of post likes. %1$d is the number of likes."
        )
        static let plural = NSLocalizedString(
            "%1$d Likes",
            comment: "Plural format string for view title displaying the number of post likes. %1$d is the number of likes."
        )
    }
}
