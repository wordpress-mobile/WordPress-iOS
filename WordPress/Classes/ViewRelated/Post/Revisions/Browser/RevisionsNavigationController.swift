class RevisionsNavigationController: UINavigationController {
    var revisionState: RevisionBrowserState? {
        didSet {
            setupForBrowserState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.setBackgroundImage(UIImage(color: UIAppColor.neutral(.shade70)), for: .default)
        navigationBar.shadowImage = UIImage(color: UIAppColor.neutral(.shade60))
    }

    private func setupForBrowserState() {
        guard let revisionView = viewControllers.first as? RevisionDiffsBrowserViewController else {
            return
        }

        revisionView.revisionState = revisionState
    }
}
