import Foundation

protocol RemoteParameter {
    var key: String { get }
    var defaultValue: LosslessStringConvertible? { get }
    var description: String { get }
}

extension RemoteParameter {
    func value<T: LosslessStringConvertible>(using remoteStore: RemoteConfigStore = .init(),
                                             overrideStore: RemoteConfigOverrideStore = .init()) -> T? {
        if let overriddenStringValue = overrideStore.overriddenValue(for: self) {
            DDLogInfo("🚩 Returning overridden value for remote config param: \(description).")
            return T(overriddenStringValue)
        }
        if let remoteValue = remoteStore.value(for: key) {
            return remoteValue as? T
        }
        DDLogInfo("🚩 Unable to resolve remote config param: \(description). Returning compile-time default.")
        return defaultValue as? T
    }
}

/// Each enum case represents a single remote parameter. Each parameter has a default value and a server value.
/// We fallback to the default value if the server value cannot be retrieved.
enum RemoteConfigParameter: CaseIterable, RemoteParameter {
    case blazeNonDismissibleStep
    case blazeFlowCompletedStep
    case wordPressPluginOverlayMaxShown
    case wordPressInAppUpdateBlockingVersion
    case jetpackInAppUpdateBlockingVersion
    case inAppUpdateFlexibleIntervalInDays

    var key: String {
        switch self {
        case .blazeNonDismissibleStep:
            return "blaze_non_dismissable_hash"
        case .blazeFlowCompletedStep:
            return "blaze_completed_step_hash"
        case .wordPressPluginOverlayMaxShown:
            return "wp_plugin_overlay_max_shown"
        case .wordPressInAppUpdateBlockingVersion:
            return "wp_in_app_update_blocking_version_ios"
        case .jetpackInAppUpdateBlockingVersion:
            return "jp_in_app_update_blocking_version_ios"
        case .inAppUpdateFlexibleIntervalInDays:
            return "in_app_update_flexible_interval_in_days_ios"
        }
    }

    var defaultValue: LosslessStringConvertible? {
        switch self {
        case .blazeNonDismissibleStep:
            return "step-4"
        case .blazeFlowCompletedStep:
            return "step-5"
        case .wordPressPluginOverlayMaxShown:
            return 3
        case .wordPressInAppUpdateBlockingVersion:
            return nil
        case .jetpackInAppUpdateBlockingVersion:
            return nil
        case .inAppUpdateFlexibleIntervalInDays:
            return nil
        }
    }

    var description: String {
        switch self {
        case .blazeNonDismissibleStep:
            return "Blaze Non-Dismissible Step"
        case .blazeFlowCompletedStep:
            return "Blaze Completed Step"
        case .wordPressPluginOverlayMaxShown:
            return "WP Plugin Overlay Max Frequency"
        case .wordPressInAppUpdateBlockingVersion:
            return "WP In-App Update Blocking Version"
        case .jetpackInAppUpdateBlockingVersion:
            return "JP In-App Update Blocking Version"
        case .inAppUpdateFlexibleIntervalInDays:
            return "In-App Update Flexible Interval (Days)"
        }
    }
}
