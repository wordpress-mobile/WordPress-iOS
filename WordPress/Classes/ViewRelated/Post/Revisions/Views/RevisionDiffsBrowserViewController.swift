import Gridicons

struct RevisionBrowserState {
    let revisions: [Revision]
    var currentIndex: Int

    func currentRevision() -> Revision {
        return revisions[currentIndex]
    }
}

class RevisionDiffsBrowserViewController: UIViewController {
    var revisionState: RevisionBrowserState?
    var diffVC: RevisionDiffViewController?
    @IBOutlet var revisionTitle: UILabel!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var nextButton: UIButton!


    private lazy var doneBarButtonItem: UIBarButtonItem = {
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        doneItem.on() { [weak self] _ in
            self?.dismiss(animated: true)
        }
        doneItem.title = "Done"
        return doneItem
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        showRevision()
        setupNavbarItems()
        setNextPreviousButtons()
    }

    private func showRevision() {
        guard let revisionState = revisionState else {
            return
        }

        let revision = revisionState.currentRevision()
        diffVC?.revision = revision
        revisionTitle?.text = revision.postTitle ?? ""
    }

    private func setNextPreviousButtons() {
        previousButton.setTitle("", for: .normal)
        previousButton.setImage(Gridicon.iconOfType(.chevronLeft).imageWithTintColor(WPStyleGuide.darkGrey()), for: .normal)
        nextButton.setTitle("", for: .normal)
        nextButton.setImage(Gridicon.iconOfType(.chevronRight).imageWithTintColor(WPStyleGuide.darkGrey()), for: .normal)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let diffVC = segue.destination as? RevisionDiffViewController {
            self.diffVC = diffVC
        }
    }

    private func setupNavbarItems() {
        navigationItem.leftBarButtonItems = [doneBarButtonItem]
        navigationItem.title = NSLocalizedString("Revision", comment: "Title of the screen that shows the revisions.")
    }
}
