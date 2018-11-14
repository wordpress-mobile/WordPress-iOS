class RevisionsNavigationController: UINavigationController {
    var revision: Revision? {
        didSet {
            setupForRevision()
        }
    }

    private func setupForRevision() {
        guard let revision = revision,
            let revisionView = viewControllers.first as? RevisionDiffsBrowserViewController else {
            return
        }

        revisionView.revision = revision
    }
}
