import Foundation
@testable import WordPress

class RemoteConfigStoreMock: RemoteConfigStore {

    var phaseThreeBlogPostUrl: String?
    var removalDeadline: String?
    var phaseNewUsersBlogPostUrl: String?
    var phaseSelfHostedBlogPostUrl: String?
    var blazeNonDismissibleStep: String?
    var blazeFlowCompletedStep: String?
    var jetpackInAppUpdateBlockingVersion: String?
    var inAppUpdateFlexibleIntervalInDays: Int?

    override func value(for key: String) -> Any? {
        if key == "phase_three_blog_post" {
            return phaseThreeBlogPostUrl
        }
        if key == "jp_deadline" {
            return removalDeadline
        }
        if key == "phase_new_users_blog_post" {
            return phaseNewUsersBlogPostUrl
        }
        if key == "phase_self_hosted_blog_post" {
            return phaseSelfHostedBlogPostUrl
        }
        if key == "blaze_non_dismissable_hash" {
            return blazeNonDismissibleStep
        }
        if key == "blaze_completed_step_hash" {
            return blazeFlowCompletedStep
        }
        if key == "jp_in_app_update_blocking_version_ios" {
            return jetpackInAppUpdateBlockingVersion
        }
        if key == "in_app_update_flexible_interval_in_days_ios" {
            return inAppUpdateFlexibleIntervalInDays
        }
        return super.value(for: key)
    }
}
