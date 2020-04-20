/// Generic type for the UIViewController in the Reader Content View
protocol ReaderContentViewController: UIViewController {
    func setTopic(_ topic: ReaderAbstractTopic?)
}


/// Reader Factory
extension WPTabBarController {

    var readerTabViewController: ReaderTabViewController? {
        readerNavigationController?.topViewController as? ReaderTabViewController
    }

    @objc func makeReaderTabViewController() -> ReaderTabViewController {
        return ReaderTabViewController(viewModel: self.readerTabViewModel, readerTabViewFactory: makeReaderTabView(_:))
    }

    @objc func makeReaderTabViewModel() -> ReaderTabViewModel {
        let viewModel = ReaderTabViewModel(readerContentFactory: makeReaderContentViewController(with:),
                                           searchNavigationFactory: navigateToReaderSearch)
        return viewModel
    }

    func makeReaderContentViewController(with topic: ReaderAbstractTopic?) -> ReaderContentViewController {
        var controller: ReaderStreamViewController
        if let topic = topic {
            controller = ReaderStreamViewController.controllerWithTopic(topic)
        } else {
            controller = ReaderStreamViewController.controllerForSavedPosts()
        }
        return controller
    }

    private func makeReaderTabView(_ viewModel: ReaderTabViewModel) -> ReaderTabView {
        return ReaderTabView(viewModel: self.readerTabViewModel)
    }
}


/// Reader Navigation
extension WPTabBarController {

    /// reader navigation methods
    func navigateToReaderSearch() {
        let searchController = ReaderSearchViewController.controller()
        navigateToReader(searchController)
    }

    func navigateToReaderSite(_ topic: ReaderSiteTopic) {
        let contentController = ReaderStreamViewController.controllerWithTopic(topic)
        navigateToReader(contentController)
    }

    func navigateToReaderTag( _ topic: ReaderTagTopic) {
        let contentController = ReaderStreamViewController.controllerWithTopic(topic)
        navigateToReader(contentController)
    }

    private func navigateToReader(_ pushControlller: UIViewController? = nil) {
        showReaderTab()
        readerNavigationController.popToRootViewController(animated: false)
        guard let controller = pushControlller else { return }
        readerNavigationController.pushViewController(controller, animated: true)
    }

    /// methods to select one of the default Reader tabs
    @objc func switchToSavedPosts() {
        navigateToReader()
        switchToTitle("Saved")
    }

    func switchToFollowedSites() {
        navigateToReader()
        readerTabViewModel.switchToTab(where: {
            ReaderHelpers.topicIsFollowing($0)
        })
    }

    func switchToDiscover() {
        navigateToReader()
        readerTabViewModel.switchToTab(where: {
            ReaderHelpers.topicIsDiscover($0)
        })
    }

    func swithcToMyLikes() {
        navigateToReader()
        readerTabViewModel.switchToTab(where: {
            ReaderHelpers.topicIsLiked($0)
        })
    }

    /// switches to a manu item topic that satisfies the given predicate with a topic value
    func switchToTopic(where predicate: (ReaderAbstractTopic) -> Bool) {
        navigateToReader()
        readerTabViewModel.switchToTab(where: predicate)
    }
    /// switches to a manu item topic whose title matched the passed value
    func switchToTitle(_ title: String) {
        navigateToReader()
        readerTabViewModel.switchToTab(where: {
            $0 == title
        })
    }
}
