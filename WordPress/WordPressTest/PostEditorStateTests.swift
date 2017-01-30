import XCTest
@testable import WordPress

class PostEditorStateTests: XCTestCase {
    var context: PostEditorStateContext!

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()

        context = nil
    }

    func testContextDefaultStateIsNew() {
        context = PostEditorStateContext(originalPostStatus: .publish, userCanPublish: true, delegate: self)

        XCTAssertEqual(PostEditorAction.publish, context.action)
    }

    func testContextPublished() {
        context = PostEditorStateContext(originalPostStatus: .publish, userCanPublish: true, delegate: self)

        context.updated(postStatus: .publish)

        XCTAssertEqual(PostEditorAction.publish, context.action)
    }

    func testContextNoContentPublishButtonDisabled() {
        context = PostEditorStateContext(originalPostStatus: .publish, userCanPublish: true, delegate: self)

        context.updated(hasContent: false)

        XCTAssertFalse(context.isPublishButtonEnabled)
    }

    func testContextChangedPublishedPostToDraft() {
        context = PostEditorStateContext(originalPostStatus: .publish, userCanPublish: true, delegate: self)

        context.updated(postStatus: .draft)

        XCTAssertEqual(PostEditorAction.update, context.action)
    }

    func testContextChangedNewPostToDraft() {
        context = PostEditorStateContext(originalPostStatus: .draft, userCanPublish: true, delegate: self)

        context.updated(postStatus: .draft)

        XCTAssertEqual(PostEditorAction.save, context.action)
    }
}

extension PostEditorStateTests: PostEditorStateContextDelegate {
    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction) {

    }
}
