extension StatsViewController {

    @objc public func showJetpackConnectionView(completion: @escaping () -> Void) {
        let controller = UIViewController.jetpackConnection(blog: self.blog!)
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
