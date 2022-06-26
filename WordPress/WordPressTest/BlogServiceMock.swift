import Foundation

class BlogServiceMock: BlogService {

    var syncAuthorsCalled = false
    var syncShouldSucceed = true
    var visibleBlogsForWPComAccountsValue: [Blog] = []

    override func syncAuthors(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        syncAuthorsCalled = true
        if syncShouldSucceed {
            blog.userID = 1
            success()
        }
        else {
            let error = NSError(domain: "", code: 0)
            failure(error)
        }

    }

    override func visibleBlogsForWPComAccounts() -> [Blog] {
        return visibleBlogsForWPComAccountsValue
    }
}
