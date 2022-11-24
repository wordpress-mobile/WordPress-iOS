extension BlogListViewController {
    @objc
    func launchSiteCreation() {
        JetpackFeaturesRemovalCoordinator.presentSiteCreationOverlayIfNeeded(in: self) {
            guard JetpackFeaturesRemovalCoordinator.siteCreationPhase() != .two else {
                return
            }

            // Display site creation flow if not in phase two
            let wizardLauncher = SiteCreationWizardLauncher()
            guard let wizard = wizardLauncher.ui else {
                return
            }
            self.present(wizard, animated: true)
            WPAnalytics.track(.enhancedSiteCreationAccessed, withProperties: ["source": "my_sites"])
        }
    }
}
