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
        // needs to be done after self has been initialized, so we do it in this method
        let doneButton = UIBarButtonItem(target: self, action: #selector(dismissHandler))
        navigationItem.rightBarButtonItem = doneButton
        if WPDeviceIdentification.isiPad() {
            navigationController?.modalPresentationStyle = .formSheet
            navigationController?.modalTransitionStyle = .coverVertical
        }
    }

    @objc
    private func dismissHandler() {
        self.dismiss(animated: true)
    }
}
