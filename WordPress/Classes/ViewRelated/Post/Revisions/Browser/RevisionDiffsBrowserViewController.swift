import Gridicons

// Revisions browser view controller
//
class RevisionDiffsBrowserViewController: UIViewController {
    var revisionState: RevisionBrowserState?

    private var operationVC: RevisionOperationViewController?
    private var pageViewController: UIPageViewController?
    private var pageManager: RevisionDiffsPageManager?
    private var visualPreviewViewController: RevisionPreviewViewController?
    private var contentPreviewState: ContentPreviewState = .html

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var strokeView: UIView!
    @IBOutlet private var revisionContainer: UIView!
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

    private lazy var moreBarButtonItem: UIBarButtonItem = {
        let image = Gridicon.iconOfType(.ellipsis)
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.frame = CGRect(origin: .zero, size: image.size)
        button.accessibilityLabel = NSLocalizedString("More", comment: "Action button to display more available options")
        button.on(.touchUpInside) { [weak self] _ in
            self?.moreWasPressed()
        }
        button.setContentHuggingPriority(.required, for: .horizontal)
        return UIBarButtonItem(customView: button)
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

    private enum ShowRevisionSource: String {
        case list
        case chevron
        case swipe
    }

    private enum ContentPreviewState {
        case html
        case visual

        var title: String {
            switch self {
            case .html:
                return NSLocalizedString("Switch to HTML Preview", comment: "Switches the Content to HTML Preview")
            case .visual:
                return NSLocalizedString("Switch to Visual Preview", comment: "Switches the Content to Rich Text Preview")
            }
        }

        func toggle() -> ContentPreviewState {
            switch self {
            case .html:
                return .visual
            case .visual:
                return .html
            }
        }
    }
}


private extension RevisionDiffsBrowserViewController {
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
        previousButton.tintColor = .neutral(.shade70)
        previousButton.on(.touchUpInside) { [weak self] _ in
            self?.showPrevious()
        }

        nextButton.setImage(Gridicon.iconOfType(.chevronRight), for: .normal)
        nextButton.tintColor = .neutral(.shade70)
        nextButton.on(.touchUpInside) { [weak self] _ in
            self?.showNext()
        }
    }

    private func setupNavbarItems() {
        navigationItem.leftBarButtonItems = [doneBarButtonItem]
        navigationItem.rightBarButtonItems = [moreBarButtonItem, loadBarButtonItem]
        navigationItem.title = NSLocalizedString("Revision", comment: "Title of the screen that shows the revisions.")
        strokeView.backgroundColor = .divider
        revisionContainer.backgroundColor = .listForeground
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

    private func triggerPreviewState() {
        contentPreviewState = contentPreviewState.toggle()

        switch contentPreviewState {
        case .html:
            hideVisualPreview()
        case .visual:
            showVisualPreview()
        }
    }

    private func showVisualPreview() {
        visualPreviewViewController = RevisionPreviewViewController.loadFromStoryboard()

        guard let vc = visualPreviewViewController else {
            return
        }

        vc.view.alpha = 0
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        add(vc)
        vc.revision = revisionState?.currentRevision()

        containerView.pinSubviewToAllEdges(vc.view)

        UIView.animate(withDuration: 0.3) {
            vc.view.alpha = 1.0
            self.nextButton.alpha = 0
            self.previousButton.alpha = 0
        }
    }

    private func hideVisualPreview() {
        UIView.animate(withDuration: 0.3, animations: {
            self.visualPreviewViewController?.view.alpha = 0
            self.nextButton.alpha = 1
            self.previousButton.alpha = 1
        }, completion: { _ in
            self.visualPreviewViewController?.remove()
        })
    }

    private func moreWasPressed() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addDefaultActionWithTitle(contentPreviewState.toggle().title) { [unowned self] _ in
            self.triggerPreviewState()
        }
        alert.addCancelActionWithTitle(NSLocalizedString("Not Now", comment: "Nicer dialog answer for \"No\"."))
        alert.popoverPresentationController?.barButtonItem = moreBarButtonItem
        present(alert, animated: true)
    }

    private func trackRevisionsDetailViewed(with source: ShowRevisionSource) {
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
