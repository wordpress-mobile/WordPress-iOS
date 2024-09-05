/// Generic type for the UIViewController in the Reader Content View
protocol ReaderContentViewController: UIViewController {
    func setContent(_ content: ReaderContent)
}

// MARK: - Reader Factory
extension WPTabBarController {
    var readerTabViewController: ReaderTabViewController? {
        readerNavigationController?.topViewController as? ReaderTabViewController
    }

    @objc func makeReaderTabViewController() -> ReaderTabViewController {
        return ReaderTabViewController(viewModel: readerTabViewModel) { [weak self] viewModel in
            guard let self else {
                return ReaderTabView(viewModel: viewModel)
            }
            return self.makeReaderTabView(viewModel)
        }
    }

    @objc func makeReaderTabViewModel() -> ReaderTabViewModel {
        let viewModel = ReaderTabViewModel(
            readerContentFactory: { content in
                if content.topicType == .discover, let topic = content.topic {
                    return ReaderCardsStreamViewController.controller(topic: topic)
                } else if let topic = content.topic {
                    return ReaderStreamViewController.controllerWithTopic(topic)
                } else {
                    return ReaderStreamViewController.controllerForContentType(content.type)
                }
            },
            searchNavigationFactory: { [weak self] in
                guard let self else {
                    return
                }
                self.navigateToReaderSearch()
            },
            tabItemsStore: ReaderTabItemsStore(),
            settingsPresenter: ReaderManageScenePresenter()
        )
        return viewModel
    }

    private func makeReaderTabView(_ viewModel: ReaderTabViewModel) -> ReaderTabView {
        return ReaderTabView(viewModel: self.readerTabViewModel)
    }
}

// MARK: - Reader Navigation
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

    func navigateToReaderTag(_ tagSlug: String) {
        let contentController = ReaderStreamViewController.controllerWithTagSlug(tagSlug)
        navigateToReader(contentController)
    }

    func navigateToReader(_ pushControlller: UIViewController? = nil) {
        showReaderTab()
        readerNavigationController?.popToRootViewController(animated: false)
        guard let controller = pushControlller else {
            return
        }
        readerNavigationController?.pushViewController(controller, animated: true)
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

    func switchToMyLikes() {
        navigateToReader()
        readerTabViewModel.switchToTab(where: {
            ReaderHelpers.topicIsLiked($0)
        })
    }

    /// switches to a menu item topic that satisfies the given predicate with a topic value
    func switchToTopic(where predicate: (ReaderAbstractTopic) -> Bool) {
        navigateToReader()
        readerTabViewModel.switchToTab(where: predicate)
    }
}
