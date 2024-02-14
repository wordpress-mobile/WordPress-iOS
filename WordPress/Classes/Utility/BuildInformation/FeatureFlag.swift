/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int, CaseIterable {
    case bloggingPrompts
    case jetpackDisconnect
    case debugMenu
    case siteIconCreator
    case betaSiteDesigns
    case commentModerationUpdate
    case compliancePopover
    case googleDomainsCard
    case newTabIcons
    case useURLSession

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .bloggingPrompts:
            return AppConfiguration.isJetpack
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .debugMenu:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest, .a8cPrereleaseTesting]
        case .siteIconCreator:
            return BuildConfiguration.current != .appStore
        case .betaSiteDesigns:
            return false
        case .commentModerationUpdate:
            return false
        case .compliancePopover:
            return true
        case .googleDomainsCard:
            return false
        case .newTabIcons:
            return true
        case .useURLSession:
            return BuildConfiguration.current != .appStore
        }
    }

    var disabled: Bool {
        return enabled == false
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

extension FeatureFlag {
    /// Descriptions used to display the feature flag override menu in debug builds
    var description: String {
        switch self {
        case .bloggingPrompts:
            return "Blogging Prompts"
        case .jetpackDisconnect:
            return "Jetpack disconnect"
        case .debugMenu:
            return "Debug menu"
        case .siteIconCreator:
            return "Site Icon Creator"
        case .betaSiteDesigns:
            return "Fetch Beta Site Designs"
        case .commentModerationUpdate:
            return "Comments Moderation Update"
        case .compliancePopover:
            return "Compliance Popover"
        case .googleDomainsCard:
            return "Google Domains Promotional Card"
        case .newTabIcons:
            return "New Tab Icons"
        case .useURLSession:
            return "Use URLSession in WordPressKit (instead of Alamofire)"
        }
    }
}

extension FeatureFlag: OverridableFlag {

    var originalValue: Bool {
        return enabled
    }

    var canOverride: Bool {
        switch self {
        case .debugMenu:
            return false
        default:
            return true
        }
    }
}
