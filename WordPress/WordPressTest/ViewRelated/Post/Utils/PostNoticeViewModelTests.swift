import Foundation
import XCTest
import Nimble

@testable import WordPress

class PostNoticeViewModelTests: XCTestCase {
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
    }

    override func tearDown() {
        context = nil
        contextManager = nil

        super.tearDown()
    }

    func testCreatesNoticeWithFailureMessageForFailedPublishedPosts() {
        // Given
        let post = PostBuilder(context).published().with(title: "Darby Ritchie").with(remoteStatus: .failed).build()

        // When
        let notice = PostNoticeViewModel(post: post).notice

        // Then
        expect(notice.title).to(equal(PostNoticeViewModel.FailureTitles.postWillBePublished))
        expect(notice.message).to(equal(post.postTitle))
    }
}
