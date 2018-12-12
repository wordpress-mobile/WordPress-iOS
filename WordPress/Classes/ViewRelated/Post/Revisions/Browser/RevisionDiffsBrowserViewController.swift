import Gridicons


class RevisionBrowserState {
    typealias RevisionSelectedBlock = (Revision) -> Void

    let revisions: [Revision]
    var currentIndex: Int
    var onRevisionSelected: RevisionSelectedBlock


    init(revisions: [Revision], currentIndex: Int, onRevisionSelected: @escaping RevisionSelectedBlock) {
        self.revisions = revisions
        self.currentIndex = currentIndex
        self.onRevisionSelected = onRevisionSelected
    }

    func currentRevision() -> Revision {
        return revisions[currentIndex]
    }

    func decreaseIndex() {
        currentIndex = max(currentIndex - 1, 0)
    }

    func increaseIndex() {
        currentIndex = min(currentIndex + 1, revisions.count)
    }
}


class RevisionDiffsBrowserViewController: UIViewController {
    var revisionState: RevisionBrowserState?

    private var operationVC: RevisionOperationViewController?
    private var pageViewController: UIPageViewController?
    private var pageManager: RevisionDiffsPageManager?

    @IBOutlet private var revisionTitle: UILabel!
    @IBOutlet private var previousButton: UIButton!
    @IBOutlet private var nextButton: UIButton!

    private lazy var doneBarButtonItem: UIBarButtonItem = {
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        doneItem.title = NSLocalizedString("Done", comment: "Label on button to dismiss revisions view")
        doneItem.on() { [weak self] _ in
            WPAnalytics.track(.postRevisionsDetailCancelled)
            self?.dismiss(animated: true)
        }
        return doneItem
    }()

    private lazy var loadBarButtonItem: UIBarButtonItem = {
        let title = NSLocalizedString("Load", comment: "Title of the screen that load selected the revisions.")
        let loadItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
        loadItem.on() { [weak self] _ in
            self?.loadRevision()
        }
        return loadItem
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupNavbarItems()
        setNextPreviousButtons()
        showRevision()
        trackRevisionsDetailViewed(with: .list)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch segue.destination {
        case let pageViewController as UIPageViewController:
            pageManager = RevisionDiffsPageManager(delegate: self)
            pageManager?.viewControllers = (revisionState?.revisions ?? []).map {
                let diffVc = RevisionDiffViewController.loadFromStoryboard()
                diffVc.revision = $0
                return diffVc
            }

            self.pageViewController = pageViewController
            self.pageViewController?.dataSource = pageManager
            self.pageViewController?.delegate = pageManager

            scroll(.forward, animated: true)
        case let operationVC as RevisionOperationViewController:
            self.operationVC = operationVC
        default:
            break
        }
    }

    private func showRevision() {
        guard let revisionState = revisionState else {
            return
        }

        let revision = revisionState.currentRevision()
        revisionTitle?.text = revision.revisionDate.mediumString()
        operationVC?.revision = revision

        updateNextPreviousButtons()
    }

    private func setNextPreviousButtons() {
        previousButton.setImage(Gridicon.iconOfType(.chevronLeft), for: .normal)
        previousButton.tintColor = WPStyleGuide.darkGrey()
        previousButton.on(.touchUpInside) { [weak self] _ in
            self?.showPrevious()
        }

        nextButton.setImage(Gridicon.iconOfType(.chevronRight), for: .normal)
        nextButton.tintColor = WPStyleGuide.darkGrey()
        nextButton.on(.touchUpInside) { [weak self] _ in
            self?.showNext()
        }
    }

    private func setupNavbarItems() {
        navigationItem.leftBarButtonItems = [doneBarButtonItem]
        navigationItem.rightBarButtonItems = [loadBarButtonItem]
        navigationItem.title = NSLocalizedString("Revision", comment: "Title of the screen that shows the revisions.")
    }

    private func updateNextPreviousButtons() {
        guard let revisionState = revisionState else {
            return
        }
        previousButton.isHidden = revisionState.currentIndex == 0
        nextButton.isHidden = revisionState.currentIndex == revisionState.revisions.count - 1
    }

    private func showNext() {
        revisionState?.increaseIndex()
        showRevision()
        scroll(.reverse)
        trackRevisionsDetailViewed(with: .chevron)
    }

    private func showPrevious() {
        revisionState?.decreaseIndex()
        showRevision()
        scroll(.forward)
        trackRevisionsDetailViewed(with: .chevron)
    }

    private func scroll(_ direction: UIPageViewController.NavigationDirection, animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard let revisionState = revisionState,
            let pageManager = pageManager,
            !pageManager.viewControllers.isEmpty else {
            return
        }

        pageViewController?.setViewControllers([pageManager.viewControllers[revisionState.currentIndex]],
                                               direction: direction,
                                               animated: animated)
    }

    private func loadRevision() {
        guard let revision = revisionState?.currentRevision() else {
            return
        }

        dismiss(animated: true) {
            self.revisionState?.onRevisionSelected(revision)
        }
    }
}


private extension RevisionDiffsBrowserViewController {
    enum ShowRevisionSource: String {
        case list
        case chevron
        case swipe
    }

    func trackRevisionsDetailViewed(with source: ShowRevisionSource) {
        WPAnalytics.track(.postRevisionsDetailViewed,
                          withProperties: [WPAppAnalyticsKeySource: source.rawValue])
    }
}


extension RevisionDiffsBrowserViewController: RevisionDiffsPageManagerDelegate {
    func pageWillScroll(to direction: UIPageViewController.NavigationDirection) {
        switch direction {
        case .forward:
            revisionState?.increaseIndex()
        case .reverse:
            revisionState?.decreaseIndex()
        }
    }

    func pageDidFinishAnimating(completed: Bool) {
        if completed {
            showRevision()
            trackRevisionsDetailViewed(with: .swipe)
        }
    }

    func currentIndex() -> Int {
        return revisionState?.currentIndex ?? 0
    }
}
