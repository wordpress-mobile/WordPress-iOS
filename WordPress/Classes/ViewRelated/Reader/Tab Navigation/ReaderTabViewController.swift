import UIKit

class ReaderTabViewController: UIViewController {

    private let viewModel: ReaderTabViewModel

    init(viewModel: ReaderTabViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = NSLocalizedString("Reader", comment: "The default title of the Reader")
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
        self.view = ReaderTabView(viewModel: viewModel)
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
