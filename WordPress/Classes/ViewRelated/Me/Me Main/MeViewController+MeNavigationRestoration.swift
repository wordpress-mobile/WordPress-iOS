/// State Restoration
extension MeViewController: UIViewControllerRestoration {

    static func configureRestoration(on instance: MeViewController) {
        instance.restorationIdentifier = "WPMeRestorationID"
        instance.restorationClass = MeViewController.self
    }

    static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                               coder: NSCoder) -> UIViewController? {
        if FeatureFlag.meMove.enabled {
            let meController = MeViewController()
            return meController
        } else {
            return WPTabBarController.sharedInstance().meViewController
        }
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        if FeatureFlag.meMove.enabled {
            // needs to be done after self has been initialized, so we do it in this method
            let doneButton = UIBarButtonItem(target: self, action: #selector(dismissHandler))
            navigationItem.rightBarButtonItem = doneButton
        }
    }

    @objc
    private func dismissHandler() {
        self.dismiss(animated: true)
    }
}
