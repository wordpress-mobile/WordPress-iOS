class RevisionsNavigationController: UINavigationController {
    var revision: Revision? {
        didSet {
            setupForRevision()
        }
    }

    override func viewDidLoad() {
        navigationBar.setBackgroundImage(UIImage(color: WPStyleGuide.darkGrey()), for: .default)
        navigationBar.shadowImage = UIImage(color: WPStyleGuide.greyDarken30())
    }

    private func setupForRevision() {
        guard let revision = revision,
            let revisionView = viewControllers.first as? RevisionDiffsBrowserViewController else {
            return
        }

        revisionView.revision = revision
    }
}
