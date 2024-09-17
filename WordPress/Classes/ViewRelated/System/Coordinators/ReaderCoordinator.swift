import UIKit

struct ReaderCoordinator {
    func showReaderTab() {
        RootViewCoordinator.sharedPresenter.showReaderTab()
    }

    func showA8C() {
        RootViewCoordinator.sharedPresenter.switchToTopic(where: { topic in
            return (topic as? ReaderTeamTopic)?.slug == ReaderTeamTopic.a8cSlug
        })
    }

    func showP2() {
        RootViewCoordinator.sharedPresenter.switchToTopic(where: { topic in
            return (topic as? ReaderTeamTopic)?.slug == ReaderTeamTopic.p2Slug
        })
    }

    func showList(named listName: String, forUser user: String) {
        let context = ContextManager.sharedInstance().mainContext
        guard let topic = ReaderListTopic.named(listName, forUser: user, in: context) else {
            return
        }

        RootViewCoordinator.sharedPresenter.switchToTopic(where: { $0 == topic })
    }
}
