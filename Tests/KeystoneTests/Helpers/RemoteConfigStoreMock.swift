import Foundation
@testable import WordPress

class RemoteConfigStoreMock: RemoteConfigStore {

    var blazeNonDismissibleStep: String?
    var blazeFlowCompletedStep: String?
    var jetpackInAppUpdateBlockingVersion: String?
    var inAppUpdateFlexibleIntervalInDays: Int?

    override func value(for key: String) -> Any? {
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
