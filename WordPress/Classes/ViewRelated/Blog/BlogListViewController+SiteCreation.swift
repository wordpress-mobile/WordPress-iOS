extension BlogListViewController {
    @objc
    func enhancedSiteCreation() {
        let wizardLauncher = SiteCreationWizardLauncher()
        guard let wizard = wizardLauncher.ui else {
            return
        }
        wizard.navigationItem.leftBarButtonItem = cancelButton()

        present(wizard, animated: true)
    }

    private func cancelButton() -> UIBarButtonItem {
        let literal = NSLocalizedString("Cancel", comment: "Cancel button. Site creation modal popover.")
        return UIBarButtonItem(title: literal, style: .plain, target: self, action: #selector(cancel))
    }

    @objc
    private func cancel() {
        dismiss(animated: true, completion: nil)
    }
}
