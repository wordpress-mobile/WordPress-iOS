extension BlogListViewController {
    @objc
    func launchSiteCreation() {
        let source = "my_sites"
        JetpackFeaturesRemovalCoordinator.presentSiteCreationOverlayIfNeeded(in: self, source: source, onDidDismiss: {
            guard JetpackFeaturesRemovalCoordinator.siteCreationPhase(blog: self.selectedBlog) != .two else {
                return
            }

            // Display site creation flow if not in phase two
            let wizardLauncher = SiteCreationWizardLauncher()
            guard let wizard = wizardLauncher.ui else {
                return
            }
            self.present(wizard, animated: true)
            SiteCreationAnalyticsHelper.trackSiteCreationAccessed(source: source)
        })
    }
}
