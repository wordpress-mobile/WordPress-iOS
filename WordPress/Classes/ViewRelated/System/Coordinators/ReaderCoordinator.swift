import UIKit

@objc
class ReaderCoordinator: NSObject {
    let readerNavigationController: UINavigationController
    let readerSplitViewController: WPSplitViewController
    let readerMenuViewController: ReaderMenuViewController

    var failureBlock: (() -> Void)? = nil

    var source: UIViewController? = nil {
        didSet {
            let hasSource = source != nil
            let sourceIsTopViewController = source == topNavigationController?.topViewController

            isNavigatingFromSource = hasSource && (sourceIsTopViewController || readerIsNotCurrentlySelected)
        }
    }

    private var isNavigatingFromSource = false

    @objc
    init(readerNavigationController: UINavigationController,
         readerSplitViewController: WPSplitViewController,
         readerMenuViewController: ReaderMenuViewController) {
        self.readerNavigationController = readerNavigationController
        self.readerSplitViewController = readerSplitViewController
        self.readerMenuViewController = readerMenuViewController

        super.init()
    }
    private func prepareToNavigate() {
        WPTabBarController.sharedInstance().showReaderTab()

        topNavigationController?.popToRootViewController(animated: isNavigatingFromSource)
    }

    func showReaderTab() {
        WPTabBarController.sharedInstance().showReaderTab()
    }

    func showDiscover() {
        prepareToNavigate()

        readerMenuViewController.showSectionForDefaultMenuItem(withOrder: .discover,
                                                               animated: isNavigatingFromSource)
    }

    func showSearch() {
        prepareToNavigate()

        readerMenuViewController.showSectionForDefaultMenuItem(withOrder: .search,
                                                               animated: isNavigatingFromSource)
    }

    func showA8CTeam() {
        prepareToNavigate()

        readerMenuViewController.showSectionForTeam(withSlug: ReaderTeamTopic.a8cTeamSlug, animated: isNavigatingFromSource)
    }

    func showMyLikes() {
        prepareToNavigate()

        readerMenuViewController.showSectionForDefaultMenuItem(withOrder: .likes,
                                                               animated: isNavigatingFromSource)
    }

    func showManageFollowing() {
        prepareToNavigate()

        readerMenuViewController.showSectionForDefaultMenuItem(withOrder: .followed, animated: false)

        if let followedViewController = topNavigationController?.topViewController as? ReaderStreamViewController {
            followedViewController.showManageSites(animated: isNavigatingFromSource)
        }
    }

    func showList(named listName: String, forUser user: String) {
        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderTopicService(managedObjectContext: context)

        guard let topic = service.topicForList(named: listName, forUser: user) else {
            failureBlock?()
            return
        }

        if !isNavigatingFromSource {
            prepareToNavigate()
        }

        let streamViewController = ReaderStreamViewController.controllerWithTopic(topic)

        streamViewController.streamLoadFailureBlock = failureBlock

        readerSplitViewController.showDetailViewController(streamViewController, sender: nil)
        readerMenuViewController.deselectSelectedRow(animated: false)
    }

    func showTag(named tagName: String) {
        if !isNavigatingFromSource {
            prepareToNavigate()
        }

        let remote = ReaderTopicServiceRemote(wordPressComRestApi: WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress()))
        let slug = remote.slug(forTopicName: tagName) ?? tagName.lowercased()
        let controller = ReaderStreamViewController.controllerWithTagSlug(slug)
        controller.streamLoadFailureBlock = failureBlock

        readerSplitViewController.showDetailViewController(controller, sender: nil)
        readerMenuViewController.deselectSelectedRow(animated: false)
    }

    func showStream(with siteID: Int, isFeed: Bool) {
        let controller = ReaderStreamViewController.controllerWithSiteID(NSNumber(value: siteID), isFeed: isFeed)
        controller.streamLoadFailureBlock = failureBlock

        if isNavigatingFromSource {
            topNavigationController?.pushViewController(controller, animated: true)
        } else {
            prepareToNavigate()

            readerSplitViewController.showDetailViewController(controller, sender: nil)
            readerMenuViewController.deselectSelectedRow(animated: false)
        }
    }

    func showPost(with postID: Int, for feedID: Int, isFeed: Bool) {
        let detailViewController = ReaderDetailViewController.controllerWithPostID(postID as NSNumber,
                                                                                   siteID: feedID as NSNumber,
                                                                                   isFeed: isFeed)

        detailViewController.postLoadFailureBlock = { [weak self, failureBlock] in
            self?.topNavigationController?.popViewController(animated: false)
            failureBlock?()
        }

        if isNavigatingFromSource {
            topNavigationController?.pushFullscreenViewController(detailViewController, animated: isNavigatingFromSource)
        } else {
            prepareToNavigate()

            topNavigationController?.pushFullscreenViewController(detailViewController, animated: isNavigatingFromSource)
            readerMenuViewController.deselectSelectedRow(animated: false)
        }
    }

    private var topNavigationController: UINavigationController? {
        guard readerIsNotCurrentlySelected == false else {
            return source?.navigationController
        }

        if readerMenuViewController.splitViewControllerIsHorizontallyCompact == false,
            let navigationController = readerSplitViewController.topDetailViewController?.navigationController {
            return navigationController
        }

        return readerNavigationController
    }

    private var readerIsNotCurrentlySelected: Bool {
        return WPTabBarController.sharedInstance().selectedViewController != readerSplitViewController
    }
}

extension ReaderTopicService {
    /// Returns an existing topic for the specified list, or creates one if one
    /// doesn't already exist.
    ///
    func topicForList(named listName: String, forUser user: String) -> ReaderListTopic? {
        let remote = ReaderTopicServiceRemote(wordPressComRestApi: WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress()))
        let sanitizedListName = remote.slug(forTopicName: listName) ?? listName.lowercased()
        let sanitizedUser = user.lowercased()
        let path = remote.path(forEndpoint: "read/list/\(sanitizedUser)/\(sanitizedListName)/posts", withVersion: ._1_2)

        if let existingTopic = findContainingPath(path) as? ReaderListTopic {
            return existingTopic
        }

        let topic = ReaderListTopic(context: managedObjectContext)
        topic.title = listName
        topic.slug = sanitizedListName
        topic.owner = user
        topic.path = path

        return topic
    }
}
