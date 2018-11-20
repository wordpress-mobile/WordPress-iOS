class RevisionsNavigationController: UINavigationController {
    var revisionState: RevisionBrowserState? {
        didSet {
            setupForBrowserState()
        }
    }

    override func viewDidLoad() {
        navigationBar.setBackgroundImage(UIImage(color: WPStyleGuide.darkGrey()), for: .default)
        navigationBar.shadowImage = UIImage(color: WPStyleGuide.greyDarken30())
    }

    private func setupForBrowserState() {
        guard let revisionView = viewControllers.first as? RevisionDiffsBrowserViewController else {
            return
        }

        revisionView.revisionState = revisionState
    }
}
