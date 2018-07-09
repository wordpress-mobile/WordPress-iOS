import UIKit

@objc
class ReaderCoordinator: NSObject {
    let readerNavigationController: UINavigationController
    let readerMenuViewController: ReaderMenuViewController

    @objc
    init(readerNavigationController: UINavigationController,
         readerMenuViewController: ReaderMenuViewController) {
        self.readerNavigationController = readerNavigationController
        self.readerMenuViewController = readerMenuViewController

        super.init()
    }
    private func prepareToNavigate() {
        WPTabBarController.sharedInstance().showReaderTab()

        readerNavigationController.popToRootViewController(animated: false)
    }

    func showReaderTab() {
        WPTabBarController.sharedInstance().showReaderTab()
    }

    func showDiscover() {
        prepareToNavigate()

        readerMenuViewController.showSectionForDefaultMenuItem(withOrder: .discover,
                                                               animated: false)
    }

    func showSearch() {
        prepareToNavigate()

        readerMenuViewController.showSectionForDefaultMenuItem(withOrder: .search,
                                                               animated: false)
    }

    func showA8CTeam() {
        prepareToNavigate()

        readerMenuViewController.showSectionForTeam(withSlug: ReaderTeamTopic.a8cTeamSlug, animated: false)
    }

    func showMyLikes() {
        prepareToNavigate()

        readerMenuViewController.showSectionForDefaultMenuItem(withOrder: .likes,
                                                               animated: false)
    }

    func showManageFollowing() {
        prepareToNavigate()

        readerMenuViewController.showSectionForDefaultMenuItem(withOrder: .followed, animated: false)

        if let followedViewController = readerNavigationController.topViewController as? ReaderStreamViewController {
            followedViewController.showManageSites(animated: false)
        }
    }

    func showList(named listName: String, forUser user: String) {
        let context = ContextManager.sharedInstance().mainContext
        let service = ReaderTopicService(managedObjectContext: context)

        guard let topic = service.topicForList(named: listName, forUser: user) else {
            return
        }

        prepareToNavigate()

        let streamViewController = ReaderStreamViewController.controllerWithTopic(topic)
        readerNavigationController.pushViewController(streamViewController,
                                                      animated: false)
    }

    func showTag(named tagName: String) {
        prepareToNavigate()

        let remote = ReaderTopicServiceRemote(wordPressComRestApi: WordPressComRestApi.anonymousApi(userAgent: WPUserAgent.wordPress()))
        let slug = remote.slug(forTopicName: tagName) ?? tagName.lowercased()
        let controller = ReaderStreamViewController.controllerWithTagSlug(slug)

        readerNavigationController.pushViewController(controller, animated: true)
    }

    func showPost(with postID: Int, for feedID: Int, isFeed: Bool) {
        prepareToNavigate()

        let detailViewController = ReaderDetailViewController.controllerWithPostID(postID as NSNumber,
                                                                                       siteID: feedID as NSNumber)
        readerNavigationController.pushFullscreenViewController(detailViewController, animated: true)
    }
}

private extension ReaderTopicService {
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
