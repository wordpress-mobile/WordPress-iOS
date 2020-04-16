import UIKit

class ReaderTabViewController: UIViewController {

    private let viewModel: ReaderTabViewModel

    private lazy var readerTabView: ReaderTabView = {
        return ReaderTabView(viewModel: viewModel)
    }()

    init(viewModel: ReaderTabViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = NSLocalizedString("Reader", comment: "The default title of the Reader")
        ReaderTabViewController.configureRestoration(on: self)
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
        self.view = readerTabView
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
        readerTabView.switchToSavedPosts()
    }
}


// MARK: - State Restoration
extension ReaderTabViewController: UIViewControllerRestoration {

    static func configureRestoration(on instance: ReaderTabViewController) {
        instance.restorationIdentifier = "WPReaderTabControllerRestorationID"
        instance.restorationClass = ReaderTabViewController.self
    }

    static let encodedIndexKey = "WPReaderTabControllerIndexRestorationKey"

    static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                               coder: NSCoder) -> UIViewController? {

        let index = Int(coder.decodeInt32(forKey: ReaderTabViewController.encodedIndexKey))

        let controller = WPTabBarController.sharedInstance().readerTabViewController
        controller?.setStartIndex(index)

        return controller
    }

    override func encodeRestorableState(with coder: NSCoder) {
        coder.encode(readerTabView.currentIndex, forKey: ReaderTabViewController.encodedIndexKey)
    }

    func setStartIndex(_ index: Int) {
        viewModel.startIndex = index
    }
}
