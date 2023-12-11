import UIKit
import Gridicons

class ReaderTabViewController: UIViewController {

    private let viewModel: ReaderTabViewModel

    private let makeReaderTabView: (ReaderTabViewModel) -> ReaderTabView

    private lazy var readerTabView: ReaderTabView = { [unowned viewModel] in
        return makeReaderTabView(viewModel)
    }()

    private let settingsButton: SpotlightableButton = SpotlightableButton(type: .custom)

    init(viewModel: ReaderTabViewModel, readerTabViewFactory: @escaping (ReaderTabViewModel) -> ReaderTabView) {
        self.viewModel = viewModel
        self.makeReaderTabView = readerTabViewFactory
        super.init(nibName: nil, bundle: nil)

        extendedLayoutIncludesOpaqueBars = true
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
        startObservingQuickStart()

        viewModel.fetchReaderMenu()
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

        if AppConfiguration.showsWhatIsNew {
            RootViewCoordinator.shared.presentWhatIsNew(on: self)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if QuickStartTourGuide.shared.isCurrentElement(.readerDiscoverSettings) {

            if viewModel.selectedIndex != ReaderTabConstants.discoverIndex {
                viewModel.showTab(at: ReaderTabConstants.discoverIndex)
            }

            settingsButton.shouldShowSpotlight = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        ReaderTracker.shared.stop(.main)

        QuickStartTourGuide.shared.endCurrentTour()
    }

    func setupNavigationButtons() {
        // Search Button
        let searchButton = UIBarButtonItem(image: UIImage.gridicon(.search),
                                           style: .plain,
                                           target: self,
                                           action: #selector(didTapSearchButton))
        searchButton.accessibilityIdentifier = ReaderTabConstants.searchButtonAccessibilityIdentifier
        searchButton.accessibilityLabel = ReaderTabConstants.searchButtonAccessibilityLabel

        // Settings Button
        settingsButton.spotlightOffset = ReaderTabConstants.spotlightOffset
        settingsButton.contentEdgeInsets = ReaderTabConstants.settingsButtonContentEdgeInsets
        settingsButton.setImage(.gridicon(.readerFollowing), for: .normal)
        settingsButton.addTarget(self, action: #selector(didTapSettingsButton), for: .touchUpInside)
        settingsButton.accessibilityIdentifier = ReaderTabConstants.settingsButtonIdentifier
        settingsButton.accessibilityLabel = ReaderTabConstants.settingsButtonAccessibilityLabel
        let settingsButton = UIBarButtonItem(customView: settingsButton)

        navigationItem.rightBarButtonItems = [searchButton, settingsButton]
    }

    override func loadView() {
        view = readerTabView

        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    @objc func willEnterForeground() {
        guard isViewOnScreen() else {
            return
        }

        ReaderTracker.shared.start(.main)
    }

    func presentDiscoverTab() {
        viewModel.shouldShowCommentSpotlight = true
        viewModel.fetchReaderMenu()
        viewModel.showTab(at: ReaderTabConstants.discoverIndex)
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

// MARK: Observing Quick Start
extension ReaderTabViewController {
    private func startObservingQuickStart() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickStartTourElementChangedNotification(_:)), name: .QuickStartTourElementChangedNotification, object: nil)
    }

    @objc private func handleQuickStartTourElementChangedNotification(_ notification: Foundation.Notification) {
        if let info = notification.userInfo,
           let element = info[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement {
            settingsButton.shouldShowSpotlight = element == .readerDiscoverSettings
        }
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

        let controller = RootViewCoordinator.sharedPresenter.readerTabViewController
        controller?.setStartIndex(index)

        return controller
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)

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
        static let settingsButtonAccessibilityLabel = NSLocalizedString(
            "reader.navigation.settings.button.label",
            value: "Reader Settings",
            comment: "Reader settings button accessibility label."
        )
        static let searchButtonAccessibilityIdentifier = "ReaderSearchBarButton"
        static let searchButtonAccessibilityLabel = NSLocalizedString(
            "reader.navigation.search.button.label",
            value: "Search",
            comment: "Reader search button accessibility label."
        )
        static let storyBoardInitError = "Storyboard instantiation not supported"
        static let restorationIdentifier = "WPReaderTabControllerRestorationID"
        static let encodedIndexKey = "WPReaderTabControllerIndexRestorationKey"
        static let discoverIndex = 1
        static let spotlightOffset = UIOffset(horizontal: 20, vertical: -10)
        static let settingsButtonContentEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
    }
}

// MARK: - WPScrollableViewController conformance
extension ReaderTabViewController: WPScrollableViewController {
    /// Scrolls the first child VC to the top if it's a `ReaderStreamViewController`.
    func scrollViewToTop() {
        guard let readerStreamVC = children.first as? ReaderStreamViewController else {
            return
        }
        readerStreamVC.scrollViewToTop()
    }
}
