extension BlogListViewController {
    @objc
    func launchSiteCreation() {
        let wizardLauncher = SiteCreationWizardLauncher()
        guard let wizard = wizardLauncher.ui else {
            return
        }
        present(wizard, animated: true)
        WPAnalytics.track(.enhancedSiteCreationAccessed, withProperties: ["source": "my_sites"])
    }
}
