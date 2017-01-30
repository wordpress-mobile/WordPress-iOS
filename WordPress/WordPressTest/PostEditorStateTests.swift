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
        context = PostEditorStateContext(userCanPublish: true, delegate: self)

        XCTAssertEqual(PostStatusState.new, context.state)
    }

    func testContextPublished() {
        context = PostEditorStateContext(userCanPublish: true, delegate: self)

        context.updated(postStatus: .publish)

        XCTAssertEqual(PostStatusState.published, context.state)
    }

    func testContextNoContentPublishButtonDisabled() {
        context = PostEditorStateContext(userCanPublish: true, delegate: self)

        context.updated(hasContent: false)

        XCTAssertFalse(context.isPublishButtonEnabled)
    }
}

extension PostEditorStateTests: PostEditorStateContextDelegate {
    func context(_ context: PostEditorStateContext, didChangeState: PostStatusState) {

    }
}
