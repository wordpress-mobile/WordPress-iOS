import UIKit

class ReaderTabViewController: UIViewController {

    private let viewModel: ReaderTabViewModel

    init(viewModel: ReaderTabViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.filterTapped = { [weak self] (fromView, completion) in
            guard let self = self else { return }
            self.viewModel.presentFilter(from: self, sourceView: fromView, completion: { [weak self] title in
                self?.dismiss(animated: true, completion: nil)
                completion(title)
            })
        }
        viewModel.settingsTapped = { [weak self] fromView in
            let tagsVC = ReaderTagsTableViewController(style: .grouped)
            let sitesVC = ReaderFollowedSitesViewController.controller()
//            sitesVC.tableView.allowsSelection = false
            let vc = TabbedViewController(items: [("Followed Tags", tagsVC), ("Followed Sites", sitesVC)])
            vc.title =  NSLocalizedString("Manage", comment: "Title for the Reader Manage screen.")
            let navigationController = UINavigationController(rootViewController: vc)
            self?.present(navigationController, animated: true, completion: nil)
        }
        title = NSLocalizedString("Reader", comment: "The default title of the Reader")
        setupSearchButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSearchButton() {
      navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search,
                                                          target: self,
                                                          action: #selector(didTapSearchButton))
    }

    override func loadView() {
        view = ReaderTabView(viewModel: viewModel)
    }
}

// MARK: - Search
extension ReaderTabViewController {

    @objc private func didTapSearchButton() {
        let searchController = ReaderSearchViewController.controller()
        navigationController?.pushViewController(searchController, animated: true)
    }
}


// MARK: - Tab Switching
extension ReaderTabViewController {
    @objc func navigateToSavedPosts() {
        guard let readerTabView = view as? ReaderTabView else {
            return
        }
        readerTabView.switchToSavedPosts()
    }
}
