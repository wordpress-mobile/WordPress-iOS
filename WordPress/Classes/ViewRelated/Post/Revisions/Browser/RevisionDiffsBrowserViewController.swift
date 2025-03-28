import UIKit
import WordPressUI

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

    private lazy var moreBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: makeMoreMenu())

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

    // MARK: - Actions

    @objc private func buttonCloseTapped() {
        WPAnalytics.track(.postRevisionsDetailCancelled)
        dismiss(animated: true)
    }
}

private extension RevisionDiffsBrowserViewController {
    private func showRevision() {
        guard let revisionState else {
            return
        }

        let revision = revisionState.currentRevision()
        revisionTitle?.text = revision.revisionDate.toMediumString()
        operationVC?.revision = revision

        updateNextPreviousButtons()
    }

    private func setNextPreviousButtons() {
        previousButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        previousButton.tintColor = UIAppColor.tint
        previousButton.on(.touchUpInside) { [weak self] _ in
            self?.showPrevious()
        }

        nextButton.setImage(UIImage(systemName: "chevron.forward"), for: .normal)
        nextButton.tintColor = UIAppColor.tint
        nextButton.on(.touchUpInside) { [weak self] _ in
            self?.showNext()
        }
    }

    private func setupNavbarItems() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: SharedStrings.Button.close, style: .plain, target: self, action: #selector(buttonCloseTapped))
        navigationItem.rightBarButtonItems = [moreBarButtonItem, loadBarButtonItem]
        navigationItem.title = NSLocalizedString("Revision", comment: "Title of the screen that shows the revisions.")
        strokeView.backgroundColor = .separator
        revisionContainer.backgroundColor = .secondarySystemGroupedBackground
    }

    private func updateNextPreviousButtons() {
        guard let revisionState else {
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
        guard let revisionState,
            let pageManager,
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

    private func makeMoreMenu() -> UIMenu {
        UIMenu(options: .displayInline, children: [
            UIDeferredMenuElement.uncached { [weak self] in
                $0(self?.makeMoreMenuActions() ?? [])
            }
        ])
    }

    private func makeMoreMenuActions() -> [UIAction] {
        let toggleMode = UIAction(title: contentPreviewState.toggle().title) { [weak self] _ in
            self?.triggerPreviewState()
        }
        return [toggleMode]
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
        @unknown default:
            fatalError()
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
