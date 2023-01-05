import Foundation
@testable import WordPress

class RemoteConfigStoreMock: RemoteConfigStore {

    var phaseThreeBlogPostUrl: String?

    override func value(for key: String) -> Any? {
        if key == "phase_three_blog_post" {
            return phaseThreeBlogPostUrl
        }
        return super.value(for: key)
    }
}
