/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int, CaseIterable {
    case jetpackDisconnect
    case debugMenu
    case unifiedAuth
    case unifiedSiteAddress
    case quickActions
    case meMove
    case floatingCreateButton
    case newReaderNavigation
    case tenor
    case homepageSettings

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .debugMenu:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        case .unifiedAuth:
            return BuildConfiguration.current == .localDeveloper
        case .unifiedSiteAddress:
            return BuildConfiguration.current == .localDeveloper
        case .quickActions:
            return true
        case .meMove:
            return true
        case .floatingCreateButton:
            return true
        case .newReaderNavigation:
            return true
        case .tenor:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        case .homepageSettings:
            return BuildConfiguration.current == .localDeveloper
        }
    }
}

/// Objective-C bridge for FeatureFlag.
///
/// Since we can't expose properties on Swift enums we use a class instead
class Feature: NSObject {
    /// Returns a boolean indicating if the feature is enabled
    @objc static func enabled(_ feature: FeatureFlag) -> Bool {
        return feature.enabled
    }
}

extension FeatureFlag: OverrideableFlag {
    /// Descriptions used to display the feature flag override menu in debug builds
    var description: String {
        switch self {
        case .jetpackDisconnect:
            return "Jetpack disconnect"
        case .debugMenu:
            return "Debug menu"
        case .unifiedAuth:
            return "Unified Auth"
        case .unifiedSiteAddress:
            return "Unified Auth - Site Address"
        case .quickActions:
            return "Quick Actions"
        case .meMove:
            return "Move the Me Scene to My Site"
        case .floatingCreateButton:
            return "Floating Create Button"
        case .newReaderNavigation:
            return "New Reader Navigation"
        case .tenor:
            return "Tenor GIF media source"
        case .homepageSettings:
            return "Homepage Settings"
        }
    }

    var canOverride: Bool {
        switch self {
        case .debugMenu:
            return false
        case .floatingCreateButton:
            return false
        case .newReaderNavigation:
            return false
        default:
            return true
        }
    }
}
