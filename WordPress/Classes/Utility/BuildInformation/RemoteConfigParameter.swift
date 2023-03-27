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
            return T.init(overriddenStringValue)
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
    case jetpackDeadline
    case phaseTwoBlogPostUrl
    case phaseThreeBlogPostUrl
    case phaseFourBlogPostUrl
    case phaseNewUsersBlogPostUrl
    case phaseSelfHostedBlogPostUrl
    case blazeNonDismissibleStep
    case blazeFlowCompletedStep
    case wordPressPluginOverlayMaxShown

    var key: String {
        switch self {
        case .jetpackDeadline:
            return "jp_deadline"
        case .phaseTwoBlogPostUrl:
            return "phase_two_blog_post"
        case .phaseThreeBlogPostUrl:
            return "phase_three_blog_post"
        case .phaseFourBlogPostUrl:
            return "phase_four_blog_post"
        case .phaseNewUsersBlogPostUrl:
            return "phase_new_users_blog_post"
        case .phaseSelfHostedBlogPostUrl:
            return "phase_self_hosted_blog_post"
        case .blazeNonDismissibleStep:
            return "blaze_non_dismissable_hash"
        case .blazeFlowCompletedStep:
            return "blaze_completed_step_hash"
        case .wordPressPluginOverlayMaxShown:
            return "wp_plugin_overlay_max_shown"
        }
    }

    var defaultValue: LosslessStringConvertible? {
        switch self {
        case .jetpackDeadline:
            return nil
        case .phaseTwoBlogPostUrl:
            return nil
        case .phaseThreeBlogPostUrl:
            return nil
        case .phaseFourBlogPostUrl:
            return nil
        case .phaseNewUsersBlogPostUrl:
            return nil
        case .phaseSelfHostedBlogPostUrl:
            return nil
        case .blazeNonDismissibleStep:
            return "step-4"
        case .blazeFlowCompletedStep:
            return "step-5"
        case .wordPressPluginOverlayMaxShown:
            return 3
        }
    }

    var description: String {
        switch self {
        case .jetpackDeadline:
            return "Jetpack Deadline"
        case .phaseTwoBlogPostUrl:
            return "Phase 2 Blog Post URL"
        case .phaseThreeBlogPostUrl:
            return "Phase 3 Blog Post URL"
        case .phaseFourBlogPostUrl:
            return "Phase 4 Blog Post URL"
        case .phaseNewUsersBlogPostUrl:
            return "Phase New Users Blog Post URL"
        case .phaseSelfHostedBlogPostUrl:
            return "Phase Self-Hosted Blog Post URL"
        case .blazeNonDismissibleStep:
            return "Blaze Non-Dismissible Step"
        case .blazeFlowCompletedStep:
            return "Blaze Completed Step"
        case .wordPressPluginOverlayMaxShown:
            return "WP Plugin Overlay Max Frequency"
        }
    }
}
