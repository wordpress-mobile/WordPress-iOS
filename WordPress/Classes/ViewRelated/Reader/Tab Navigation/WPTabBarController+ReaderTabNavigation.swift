/// Generic type for the UIViewController in the Reader Content View
protocol ReaderContentViewController: UIViewController {
    func setContent(_ content: ReaderContent)
}

// MARK: - Reader Factory
extension WPTabBarController {
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
                    return ReaderDiscoverViewController(topic: topic)
                } else if let topic = content.topic {
                    return ReaderStreamViewController.controllerWithTopic(topic)
                } else {
                    return ReaderStreamViewController.controllerForContentType(content.type)
                }
            },
            searchNavigationFactory: { [weak self] in
                self?.showReader(path: .search)
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
    func showReader(path: ReaderNavigationPath?) {
        showReaderTab()
        if let path {
            navigate(to: path)
        }
    }

    private func navigate(to path: ReaderNavigationPath) {
        switch path {
        case .recent:
            readerTabViewModel.switchToTab(where: ReaderHelpers.topicIsFollowing)
        case .discover:
            readerTabViewModel.switchToTab(where: ReaderHelpers.topicIsDiscover)
        case .likes:
            readerTabViewModel.switchToTab(where: ReaderHelpers.topicIsLiked)
        case .search:
            showReaderDetails(ReaderSearchViewController.controller())
        case .subscriptions:
            ReaderManageScenePresenter().present(on: self, selectedSection: .sites, animated: true, completion: nil)
        case let .post(postID, siteID, isFeed):
            showReaderDetails(ReaderDetailViewController.controllerWithPostID(NSNumber(value: postID), siteID: NSNumber(value: siteID), isFeed: isFeed))
        case let .postURL(url):
            showReaderDetails(ReaderDetailViewController.controllerWithPostURL(url))
        case let .tag(slug):
            showReaderDetails(ReaderStreamViewController.controllerWithTagSlug(slug))
        case let .topic(topic):
            showReaderDetails(ReaderStreamViewController.controllerWithTopic(topic))
        }
    }

    private func showReaderDetails(_ viewController: UIViewController) {
        readerNavigationController?.popToRootViewController(animated: false)
        readerNavigationController?.pushViewController(viewController, animated: true)
    }
}
