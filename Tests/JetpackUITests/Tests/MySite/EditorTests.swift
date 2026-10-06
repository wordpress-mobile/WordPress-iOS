import XCTest

final class EditorTests: JetpackUITestCase {
    func testOpenAndDiscardNewPost() throws {
        try MySiteScreen(app: app)
            .goToNewPost()
            .closeAndDiscardChanges()
    }
}
