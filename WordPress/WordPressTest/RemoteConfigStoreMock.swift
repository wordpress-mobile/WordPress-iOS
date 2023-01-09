import Foundation
@testable import WordPress

class RemoteConfigStoreMock: RemoteConfigStore {

    var phaseThreeBlogPostUrl: String?
    var removalDeadline: String?

    override func value(for key: String) -> Any? {
        if key == "phase_three_blog_post" {
            return phaseThreeBlogPostUrl
        }
        if key == "jp_deadline" {
            return removalDeadline
        }
        return super.value(for: key)
    }
}
