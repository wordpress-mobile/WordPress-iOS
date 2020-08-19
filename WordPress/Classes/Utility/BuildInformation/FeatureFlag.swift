/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
@objc
enum FeatureFlag: Int, CaseIterable {
    case jetpackDisconnect
    case debugMenu
    case unifiedAuth
    case unifiedSiteAddress
    case unifiedGoogle
    case unifiedApple
    case unifiedSignup
    case meMove
    case floatingCreateButton
    case newReaderNavigation
    case swiftCoreData
    case homepageSettings
    case readerImprovementsPhase2
    case gutenbergMentions
    case gutenbergModalLayoutPicker
    case whatIsNew

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
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        case .unifiedSiteAddress:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        case .unifiedGoogle:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        case .unifiedApple:
            return BuildConfiguration.current ~= [.localDeveloper, .a8cBranchTest]
        case .unifiedSignup:
            return false
        case .meMove:
            return true
        case .floatingCreateButton:
            return true
        case .newReaderNavigation:
            return true
        case .swiftCoreData:
            return BuildConfiguration.current == .localDeveloper
        case .homepageSettings:
            return true
        case .readerImprovementsPhase2:
            return false
        case .gutenbergMentions:
            return true
        case .gutenbergModalLayoutPicker:
            return false
        case .whatIsNew:
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
        case .unifiedGoogle:
            return "Unified Auth - Google"
        case .unifiedApple:
            return "Unified Auth - Apple"
        case .unifiedSignup:
            return "Unified Auth - Sign Up"
        case .meMove:
            return "Move the Me Scene to My Site"
        case .floatingCreateButton:
            return "Floating Create Button"
        case .newReaderNavigation:
            return "New Reader Navigation"
        case .swiftCoreData:
            return "Migrate Core Data Stack to Swift"
        case .homepageSettings:
            return "Homepage Settings"
        case .readerImprovementsPhase2:
            return "Reader Improvements Phase 2"
        case .gutenbergMentions:
            return "Mentions in Gutenberg"
        case .gutenbergModalLayoutPicker:
            return "Gutenberg Modal Layout Picker"
        case .whatIsNew:
            return "What's New / Feature Announcement"
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
        case .swiftCoreData:
            return false
        default:
            return true
        }
    }
}
