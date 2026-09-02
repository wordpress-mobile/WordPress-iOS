extension StatsViewController {

    @objc public func showJetpackConnectionView(completion: @escaping () -> Void) {
        // Expected non-nil now that `blog` is strongly held; bail rather than
        // force-unwrap. Don't call `completion()` — it re-enters initStats and loops.
        guard let blog = self.blog else { return }
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
