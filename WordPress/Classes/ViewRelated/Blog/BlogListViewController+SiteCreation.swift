extension BlogListViewController {
    @objc
    func enhancedSiteCreation() {
        let wizardLauncher = SiteCreationWizardLauncher()
        let wizard = wizardLauncher.ui
        present(wizard, animated: true)
    }
}
