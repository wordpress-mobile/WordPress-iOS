class RevisionsNavigationController: UINavigationController {
    var post: AbstractPost? {
        didSet {
            setupForPost()
        }
    }

    private func setupForPost() {
        guard let post = post,
            let revisionView = viewControllers.first as? RevisionDiffsBrowserViewController else {
            return
        }

        revisionView.post = post
    }
}
