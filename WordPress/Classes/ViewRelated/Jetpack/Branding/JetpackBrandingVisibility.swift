/// An enum that unifies the checks to limit the visibility of the Jetpack branding elements (banners and badges)
///
/// This thing was born as an enum but at the time of writing had only one case in use.
/// There is no reason to have that case linger around, it's been left merely to avoid changing its 15 usages.
enum JetpackBrandingVisibility {

    case all

    func isEnabled(
        isWordPress: Bool,
        isDotComAvailable: Bool,
        shouldShowJetpackFeatures: Bool
    ) -> Bool {
        switch self {
        case .all:
            return isWordPress && isDotComAvailable && shouldShowJetpackFeatures
        }
    }

    @available(*, deprecated, message: "Use the isEnabled function to allow injecting the configuration.")
    var enabled: Bool {
        return isEnabled(
            isWordPress: AppConfiguration.isWordPress,
            isDotComAvailable: AccountHelper.isDotcomAvailable(),
            shouldShowJetpackFeatures: JetpackFeaturesRemovalCoordinator.shouldShowJetpackFeatures()
        )
    }
}
