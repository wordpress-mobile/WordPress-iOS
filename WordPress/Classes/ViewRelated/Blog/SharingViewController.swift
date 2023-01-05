import Foundation

extension SharingViewController {

    static let jetpackBadgePadding: CGFloat = 30

    @objc
    static func jetpackBrandingVisibile() -> Bool {
        return JetpackBrandingVisibility.all.enabled
    }

    @objc
    func makeJetpackBadge() -> UIView {
        let textProvider = JetpackBrandingTextProvider(screen: JetpackBadgeScreen.sharing)
        let badge = JetpackButton.makeBadgeView(title: textProvider.brandingText(),
                                                topPadding: Self.jetpackBadgePadding,
                                                bottomPadding: Self.jetpackBadgePadding,
                                                target: self,
                                                selector: #selector(presentJetpackOverlay))
        return badge
    }

    @objc
    func presentJetpackOverlay() {
        JetpackBrandingCoordinator.presentOverlay(from: self)
        JetpackBrandingAnalyticsHelper.trackJetpackPoweredBadgeTapped(screen: .sharing)
    }
}
