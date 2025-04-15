import Foundation

class BlogServiceMock: BlogService {

    var syncAuthorsCalled = false
    var syncShouldSucceed = true

    override func syncAuthors(for blog: Blog, success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        syncAuthorsCalled = true
        if syncShouldSucceed {
            blog.userID = 1
            success()
        }
        else {
            failure(testError())
        }

    }

}
