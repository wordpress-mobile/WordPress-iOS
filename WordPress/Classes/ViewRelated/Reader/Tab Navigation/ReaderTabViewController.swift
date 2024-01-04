import UIKit
import Gridicons

class ReaderTabViewController: UIViewController {

    private let viewModel: ReaderTabViewModel

    private let makeReaderTabView: (ReaderTabViewModel) -> ReaderTabView

    private lazy var readerTabView: ReaderTabView = { [unowned viewModel] in
        return makeReaderTabView(viewModel)
    }()

    init(viewModel: ReaderTabViewModel, readerTabViewFactory: @escaping (ReaderTabViewModel) -> ReaderTabView) {
        self.viewModel = viewModel
        self.makeReaderTabView = readerTabViewFactory
        super.init(nibName: nil, bundle: nil)

        title = ReaderTabConstants.title

        ReaderTabViewController.configureRestoration(on: self)

        ReaderCardService().clean()

        viewModel.filterTapped = { [weak self] (filter, fromView, completion) in
            guard let self = self else {
                return
            }

            self.viewModel.presentFilter(filter: filter, from: self, sourceView: fromView) { [weak self] topic in
                self?.dismiss(animated: true, completion: nil)
                completion(topic)
            }
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

            // TODO: Revisit Reader spotlight
        }
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        ReaderTracker.shared.stop(.main)

        QuickStartTourGuide.shared.endCurrentTour()
        navigationController?.setNavigationBarHidden(false, animated: animated)
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

// MARK: Observing Quick Start
extension ReaderTabViewController {
    private func startObservingQuickStart() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickStartTourElementChangedNotification(_:)), name: .QuickStartTourElementChangedNotification, object: nil)
    }

    @objc private func handleQuickStartTourElementChangedNotification(_ notification: Foundation.Notification) {
        // TODO: Revisit Reader spotlight
//        if let info = notification.userInfo,
//           let element = info[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement {
//        }
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
        static let discoverIndex = 0
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
