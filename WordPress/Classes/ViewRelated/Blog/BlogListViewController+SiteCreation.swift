extension BlogListViewController {
    @objc
    func launchSiteCreation() {
        if FeatureFlag.enhancedSiteCreation.enabled {
            enhancedSiteCreation()
        } else {
            showAddNewWordPress()
        }
    }

    @objc
    func enhancedSiteCreation() {
        let wizardLauncher = SiteCreationWizardLauncher()
        guard let wizard = wizardLauncher.ui else {
            return
        }
        present(wizard, animated: true)
        WPAnalytics.track(.enhancedSiteCreationAccessed)
    }
}
