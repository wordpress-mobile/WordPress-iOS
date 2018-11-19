import Gridicons

class RevisionBrowserState: SelectedRevisionLoadedProtocol {
    let post: AbstractPost?
    let revisions: [Revision]
    var currentIndex: Int
    var selectedRevisionLoaded: SelectedRevisionBlock


    init(post: AbstractPost?, revisions: [Revision], currentIndex: Int, selectedRevisionLoaded: @escaping SelectedRevisionBlock) {
        self.post = post
        self.revisions = revisions
        self.currentIndex = currentIndex
        self.selectedRevisionLoaded = selectedRevisionLoaded
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
    }

    private func showPrevious() {
        revisionState?.decreaseIndex()
        showRevision()
    }

    private func loadRevision() {
        guard let blog = revisionState?.post?.blog,
            let revision = revisionState?.currentRevision() else {
            return
        }

        SVProgressHUD.show(withStatus: NSLocalizedString("Loading...", comment: "Text displayed in HUD while a revision post is loading."))

        let service = PostService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.getPostWithID(revision.revisionId, for: blog, success: { (post) in
            SVProgressHUD.dismiss()

            self.revisionState?.selectedRevisionLoaded(post)
            self.dismiss(animated: true, completion: nil)
        }, failure: { error in
            DDLogError("Error loading revision: \(error.localizedDescription)")
            SVProgressHUD.showDismissibleError(withStatus: NSLocalizedString("Error occurred\nduring loading", comment: "Text displayed in HUD while a post revision is being loaded."))
        })
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
