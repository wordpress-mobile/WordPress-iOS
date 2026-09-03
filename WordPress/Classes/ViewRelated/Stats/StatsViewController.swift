import WordPressShared

extension StatsViewController {

    @objc public func showJetpackConnectionView(completion: @escaping () -> Void) {
        // `blog` should be non-nil now that the property is strongly held. Report a
        // non-fatal (don't call `completion()` — it re-enters initStats and loops).
        guard let blog = self.blog else {
            return wpAssertionFailure("showJetpackConnectionView called with a nil blog")
        }
        let controller = UIViewController.jetpackConnection(blog: blog)
        controller.completionBlock = { [weak controller] in
            guard let controller else { return }
            controller.view?.removeFromSuperview()
            controller.removeFromParent()
            completion()
        }

        self.addChild(controller)
        self.view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.pinEdges()
    }
}
