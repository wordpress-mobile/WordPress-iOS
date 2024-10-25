/// Generic type for the UIViewController in the Reader Content View
protocol ReaderContentViewController: UIViewController {
    func setContent(_ content: ReaderContent)
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
            // TODO: (reader) implement
            break
        case .discover:
            // TODO: (reader) implement
            break
        case .likes:
            // TODO: (reader) implement
            break
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
