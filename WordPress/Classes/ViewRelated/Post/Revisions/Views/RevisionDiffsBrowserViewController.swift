class RevisionDiffsBrowserViewController: UIViewController {
    var post: AbstractPost?
    var diffVC: RevisionDiffViewController?


    private lazy var doneBarButtonItem: UIBarButtonItem = {
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        doneItem.on() { [weak self] _ in
            self?.dismiss(animated: true)
        }
        doneItem.title = "Done"
        //        let doneItem = UIBarButtonItem(customView: self.doneButton)
        //        doneItem.accessibilityLabel = NSLocalizedString("Close", comment: "Action button to close edior and cancel changes or insertion of post")
        //        doneItem.accessibilityIdentifier = "Close"
        return doneItem
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        showRevision()
        setupNavbarItems()
    }

    private func showRevision() {
        guard let revision = post?.revisions?.first as? Revision else {
            return
        }

        diffVC?.revision = revision
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let diffVC = segue.destination as? RevisionDiffViewController {
            self.diffVC = diffVC
        }
    }

    private func setupNavbarItems() {
        navigationItem.leftBarButtonItems = [doneBarButtonItem]
    }
}
