/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int, CaseIterable {
    case jetpackDisconnect
    case debugMenu
    case siteIconCreator
    case quickStartForExistingUsers
    case qrLogin
    case betaSiteDesigns
    case featureHighlightTooltip
    case jetpackPowered
    case jetpackPoweredBottomSheet
    case contentMigration
    case newJetpackLandingScreen
    case newWordPressLandingScreen
    case newCoreDataContext
    case jetpackIndividualPluginSupport
    case siteCreationDomainPurchasing
    case readerUserBlocking
    case personalizeHomeTab
    case commentModerationUpdate
    case compliancePopover
    case domainFocus
    case nativePhotoPicker
    case readerImprovements // pcdRpT-3Eb-p2

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        switch self {
        case .jetpackDisconnect:
            return BuildConfiguration.current == .localDeveloper
        case .debugMenu:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest, .a8cPrereleaseTesting]
        case .siteIconCreator:
            return BuildConfiguration.current != .appStore
        case .quickStartForExistingUsers:
            return true
        case .qrLogin:
            return true
        case .betaSiteDesigns:
            return false
        case .featureHighlightTooltip:
            return true
        case .jetpackPowered:
            return true
        case .jetpackPoweredBottomSheet:
            return true
        case .contentMigration:
            return true
        case .newJetpackLandingScreen:
            return true
        case .newWordPressLandingScreen:
            return true
        case .newCoreDataContext:
            return true
        case .jetpackIndividualPluginSupport:
            return AppConfiguration.isJetpack
        case .siteCreationDomainPurchasing:
            return false
        case .readerUserBlocking:
            return true
        case .personalizeHomeTab:
            return AppConfiguration.isJetpack
        case .commentModerationUpdate:
            return false
        case .compliancePopover:
            return true
        case .domainFocus:
            return true
        case .nativePhotoPicker:
            return true
        case .readerImprovements:
            return false
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
        case .jetpackDisconnect:
            return "Jetpack disconnect"
        case .debugMenu:
            return "Debug menu"
        case .siteIconCreator:
            return "Site Icon Creator"
        case .quickStartForExistingUsers:
            return "Quick Start For Existing Users"
        case .qrLogin:
            return "QR Code Login"
        case .betaSiteDesigns:
            return "Fetch Beta Site Designs"
        case .featureHighlightTooltip:
            return "Feature Highlight Tooltip"
        case .jetpackPowered:
            return "Jetpack powered banners and badges"
        case .jetpackPoweredBottomSheet:
            return "Jetpack powered bottom sheet"
        case .contentMigration:
            return "Content Migration"
        case .newJetpackLandingScreen:
            return "New Jetpack landing screen"
        case .newWordPressLandingScreen:
            return "New WordPress landing screen"
        case .newCoreDataContext:
            return "Use new Core Data context structure (Require app restart)"
        case .jetpackIndividualPluginSupport:
            return "Jetpack Individual Plugin Support"
        case .siteCreationDomainPurchasing:
            return "Site Creation Domain Purchasing"
        case .readerUserBlocking:
            return "Reader User Blocking"
        case .personalizeHomeTab:
            return "Personalize Home Tab"
        case .commentModerationUpdate:
            return "Comments Moderation Update"
        case .compliancePopover:
            return "Compliance Popover"
        case .domainFocus:
            return "Domain Focus"
        case .nativePhotoPicker:
            return "Native Photo Picker"
        case .readerImprovements:
            return "Reader Improvements v1"
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
