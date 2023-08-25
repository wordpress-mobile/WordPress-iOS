/// State Restoration
extension MeViewController: UIViewControllerRestoration {

    static func configureRestoration(on instance: MeViewController) {
        instance.restorationIdentifier = "WPMeRestorationID"
        instance.restorationClass = MeViewController.self
    }

    static func viewController(withRestorationIdentifierPath identifierComponents: [String],
                               coder: NSCoder) -> UIViewController? {
       return MeViewController()
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }

    @objc
    private func dismissHandler() {
        self.dismiss(animated: true)
    }
}
