class RevisionsNavigationController: UINavigationController {
    var revisionState: RevisionBrowserState? {
        didSet {
            setupForBrowserState()
        }
    }

    override func viewDidLoad() {
        navigationBar.setBackgroundImage(UIImage(color: .neutral(shade: .shade700)), for: .default)
        navigationBar.shadowImage = UIImage(color: .neutral(shade: .shade600))
    }

    private func setupForBrowserState() {
        guard let revisionView = viewControllers.first as? RevisionDiffsBrowserViewController else {
            return
        }

        revisionView.revisionState = revisionState
    }
}
