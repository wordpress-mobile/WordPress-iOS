import UIKit

class ReaderTabViewController: UIViewController {

    private let viewModel: ReaderTabViewModel

    private let makeReaderTabView: (ReaderTabViewModel) -> ReaderTabView

    private lazy var readerTabView: ReaderTabView = {
        return makeReaderTabView(viewModel)
    }()

    init(viewModel: ReaderTabViewModel, readerTabViewFactory: @escaping (ReaderTabViewModel) -> ReaderTabView) {
        self.viewModel = viewModel
        self.makeReaderTabView = readerTabViewFactory
        super.init(nibName: nil, bundle: nil)

        title = ReaderTabConstants.title
        setupNavigationButtons()

        ReaderTabViewController.configureRestoration(on: self)

        ReaderCardService().clean()

        viewModel.filterTapped = { [weak self] (fromView, completion) in
            guard let self = self else {
                return
            }

            self.viewModel.presentFilter(from: self, sourceView: fromView, completion: { [weak self] topic in
                self?.dismiss(animated: true, completion: nil)
                completion(topic)
            })
        }

        NotificationCenter.default.addObserver(self, selector: #selector(defaultAccountDidChange(_:)), name: NSNotification.Name.WPAccountDefaultWordPressComAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError(ReaderTabConstants.storyBoardInitError)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ReaderTracker.shared.start(.main)

        if FeatureFlag.whatIsNew.enabled {
            WPTabBarController.sharedInstance()?.presentWhatIsNew(on: self)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        ReaderTracker.shared.stop(.main)
    }

    func setupNavigationButtons() {
        // Settings Button
        let settingsButton = UIBarButtonItem(image: UIImage.gridicon(.cog),
                                             style: .plain,
                                             target: self,
                                             action: #selector(didTapSettingsButton))
        settingsButton.accessibilityIdentifier = ReaderTabConstants.settingsButtonIdentifier

        // Search Button
        let searchButton = UIBarButtonItem(barButtonSystemItem: .search,
                                           target: self,
                                           action: #selector(didTapSearchButton))
        searchButton.accessibilityIdentifier = ReaderTabConstants.searchButtonAccessibilityIdentifier
        navigationItem.rightBarButtonItems = [searchButton, settingsButton]
    }

    override func loadView() {
        view = readerTabView
    }

    @objc func willEnterForeground() {
        guard isViewOnScreen() else {
            return
        }

        ReaderTracker.shared.start(.main)
    }
}


// MARK: - Navigation Buttons
extension ReaderTabViewController {
    @objc private func didTapSettingsButton() {
        viewModel.presentManage(from: self)
    }

    @objc private func didTapSearchButton() {
        viewModel.navigateToSearch()
    }
}


// MARK: - State Restoration
extension ReaderTabViewController: UIViewControllerRestoration {

    static func configureRestoration(on instance: ReaderTabViewController) {
        instance.restorationIdentifier = ReaderTabConstants.restorationIdentifier
        instance.restorationClass = ReaderTabViewController.self
    }

    static let encodedIndexKey = ReaderTabConstants.encodedIndexKey

    static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                               coder: NSCoder) -> UIViewController? {

        let index = Int(coder.decodeInt32(forKey: ReaderTabViewController.encodedIndexKey))

        let controller = WPTabBarController.sharedInstance().readerTabViewController
        controller?.setStartIndex(index)

        return controller
    }

    override func encodeRestorableState(with coder: NSCoder) {
        coder.encode(viewModel.selectedIndex, forKey: ReaderTabViewController.encodedIndexKey)
    }

    func setStartIndex(_ index: Int) {
        viewModel.selectedIndex = index
    }
}

// MARK: - Notifications
extension ReaderTabViewController {
    // Ensure that topics and sites are synced when account changes
    @objc private func defaultAccountDidChange(_ notification: Foundation.Notification) {
        loadView()
    }
}

// MARK: - Constants
extension ReaderTabViewController {
    private enum ReaderTabConstants {
        static let title = NSLocalizedString("Reader", comment: "The default title of the Reader")
        static let settingsButtonIdentifier = "ReaderSettingsButton"
        static let searchButtonAccessibilityIdentifier = "ReaderSearchBarButton"
        static let storyBoardInitError = "Storyboard instantiation not supported"
        static let restorationIdentifier = "WPReaderTabControllerRestorationID"
        static let encodedIndexKey = "WPReaderTabControllerIndexRestorationKey"
    }
}
