import Foundation

extension SharingViewController {
    @objc
    static func jetpackBrandingVisibile() -> Bool {
        return JetpackBrandingVisibility.all.enabled
    }

    @objc
    func presentJetpackOverlay() {
        JetpackBrandingCoordinator.presentOverlay(from: self)
        JetpackBrandingAnalyticsHelper.trackJetpackPoweredBadgeTapped(screen: .sharing)
    }
}
