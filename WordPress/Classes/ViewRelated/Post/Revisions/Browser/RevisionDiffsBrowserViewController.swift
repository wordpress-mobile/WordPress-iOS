import Gridicons
import WordPressFlux

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
    var diffVC: RevisionDiffViewController?
    var operationVC: RevisionOperationViewController?
    @IBOutlet var revisionTitle: UILabel!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var nextButton: UIButton!


    private lazy var doneBarButtonItem: UIBarButtonItem = {
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        doneItem.on() { [weak self] _ in
            WPAnalytics.track(.postRevisionsDetailCancelled)
            self?.dismiss(animated: true)
        }
        doneItem.title = NSLocalizedString("Done", comment: "Label on button to dismiss revisions view")
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

    private func showRevision() {
        guard let revisionState = revisionState else {
            return
        }

        let revision = revisionState.currentRevision()
        diffVC?.revision = revision
        revisionTitle?.text = revision.revisionDate.mediumString()
        operationVC?.revision = revision

        updateNextPreviousButtons()
    }

    private func setNextPreviousButtons() {
        previousButton.setTitle("", for: .normal)
        previousButton.setImage(Gridicon.iconOfType(.chevronLeft), for: .normal)
        previousButton.tintColor = WPStyleGuide.darkGrey()
        previousButton.on(.touchUpInside) { [weak self] _ in
            self?.showPrevious()
        }

        nextButton.setTitle("", for: .normal)
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
        trackRevisionsDetailViewed(with: .chevron)
    }

    private func showPrevious() {
        revisionState?.decreaseIndex()
        showRevision()
        trackRevisionsDetailViewed(with: .chevron)
    }

    private func loadRevision() {
        guard let revision = revisionState?.currentRevision() else {
            return
        }

        dismiss(animated: true) {
            self.revisionState?.onRevisionSelected(revision)
        }

        // Temp code to demonstrate how this will look
        let notice = Notice(title: "Revision loaded", message: nil, feedbackType: .success, notificationInfo: nil, actionTitle: "Undo", cancelTitle: nil) { (happened) in

        }
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch segue.destination {
        case let diffVC as RevisionDiffViewController:
            self.diffVC = diffVC
        case let operationVC as RevisionOperationViewController:
            self.operationVC = operationVC
        default:
            break
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
