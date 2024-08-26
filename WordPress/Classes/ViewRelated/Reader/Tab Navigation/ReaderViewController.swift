import UIKit

// TODO: (wpsidebar) integrate with WPTabBarController to remove duplication
final class ReaderViewController: UIViewController {
    lazy var readerTabViewModel: ReaderTabViewModel = {
        let viewModel = ReaderTabViewModel(
            readerContentFactory: { [weak self] content in
                if content.topicType == .discover, let topic = content.topic {
                    let controller = ReaderCardsStreamViewController.controller(topic: topic)
                    controller.shouldShowCommentSpotlight = self?.readerTabViewModel.shouldShowCommentSpotlight ?? false
                    return controller
                } else if let topic = content.topic {
                    return ReaderStreamViewController.controllerWithTopic(topic)
                } else {
                    return ReaderStreamViewController.controllerForContentType(content.type)
                }
            },
            searchNavigationFactory: { [weak self] in
                self?.openSeach()
            },
            tabItemsStore: ReaderTabItemsStore(),
            settingsPresenter: ReaderManageScenePresenter()
        )
        viewModel.isSidebarModeEnabled = true
        return viewModel
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewController = ReaderTabViewController(viewModel: readerTabViewModel) { [weak self] viewModel in
            guard let self else {
                return ReaderTabView(viewModel: viewModel)
            }
            return self.makeReaderTabView(viewModel)
        }
        viewController.isSidebarModeEnabled = false

        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(viewController.view)
        viewController.didMove(toParent: self)
    }

    private func makeReaderContentViewController(with content: ReaderContent) -> ReaderContentViewController {
        if content.topicType == .discover, let topic = content.topic {
            let controller = ReaderCardsStreamViewController.controller(topic: topic)
            controller.shouldShowCommentSpotlight = readerTabViewModel.shouldShowCommentSpotlight
            return controller
        } else if let topic = content.topic {
            return ReaderStreamViewController.controllerWithTopic(topic)
        } else {
            return ReaderStreamViewController.controllerForContentType(content.type)
        }
    }

    private func makeReaderTabView(_ viewModel: ReaderTabViewModel) -> ReaderTabView {
        return ReaderTabView(viewModel: self.readerTabViewModel)
    }

    private func openSeach() {
        let searchVC = ReaderSearchViewController.controller(withSearchText: "")
        navigationController?.pushViewController(searchVC, animated: true)
    }
}
