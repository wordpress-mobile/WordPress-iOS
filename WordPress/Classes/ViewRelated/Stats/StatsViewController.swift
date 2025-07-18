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

    /// Shows the stats view controller for the given blog, using the new stats UI if the feature flag is enabled
    @objc public static func show(for blog: Blog, from viewController: UIViewController) {
        if FeatureFlag.newStats.enabled {
            let statsVC = StatsHostingViewController(blog: blog)
            statsVC.hidesBottomBarWhenPushed = true
            viewController.navigationController?.pushViewController(statsVC, animated: true)
        } else {
            // Use the existing Objective-C method
            show(for: blog, from: viewController)
        }
    }
}
