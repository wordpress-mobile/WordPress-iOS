import UIKit


/// New Reader Dependencies
extension WPTabBarController {

    var readerTabViewController: ReaderTabViewController? {
        readerNavigationController?.topViewController as? ReaderTabViewController
    }

    @objc func makeReaderTabViewController() -> ReaderTabViewController {
        return ReaderTabViewController(viewModel: self.readerTabViewModel, readerTabViewFactory: makeReaderTabView(_:))
    }

    @objc func makeReaderTabViewModel() -> ReaderTabViewModel {
        return ReaderTabViewModel()
    }

    private func makeReaderTabView(_ viewModel: ReaderTabViewModel) -> ReaderTabView {
        return ReaderTabView(viewModel: self.readerTabViewModel)
    }

    // convenience navigation methods
    @objc func navigateToReaderSearch() {
        let searchController = ReaderSearchViewController.controller()
        self.readerNavigationController.pushViewController(searchController, animated: true)
    }

    @objc func switchToSavedPosts() {
        self.readerTabViewModel.navigate(matches: {
            $0 == "Saved"
        })
    }

    @objc func switchToFollowedSites() {
        self.readerTabViewModel.navigate(matches: {
            ReaderHelpers.topicIsFollowing($0)
        })
    }

    @objc func switchToDiscover() {
        self.readerTabViewModel.navigate(matches: {
            ReaderHelpers.topicIsDiscover($0)
        })
    }

    @objc func swithcToMyLikes() {
        self.readerTabViewModel.navigate(matches: {
            ReaderHelpers.topicIsLiked($0)
        })
    }
}
