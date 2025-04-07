import UIKit

extension SharingViewController {

    static let jetpackBadgePadding: CGFloat = 30

    @objc
    public static func jetpackBrandingVisibile() -> Bool {
        return JetpackBrandingVisibility.all.enabled
    }

    @objc
    public func makeJetpackBadge() -> UIView {
        let textProvider = JetpackBrandingTextProvider(screen: JetpackBadgeScreen.sharing)
        let badge = JetpackButton.makeBadgeView(title: textProvider.brandingText(),
                                                topPadding: Self.jetpackBadgePadding,
                                                bottomPadding: Self.jetpackBadgePadding,
                                                target: self,
                                                selector: #selector(presentJetpackOverlay))
        return badge
    }

    @objc
    public func presentJetpackOverlay() {
        JetpackBrandingCoordinator.presentOverlay(from: self)
        JetpackBrandingAnalyticsHelper.trackJetpackPoweredBadgeTapped(screen: .sharing)
    }

    // MARK: Twitter Deprecation

    @objc
    public func makeTwitterDeprecationFooterView() -> TwitterDeprecationTableFooterView {
        let footerView = TwitterDeprecationTableFooterView()
        footerView.presentingViewController = self
        footerView.source = "social_connection_list"

        return footerView
    }
}
