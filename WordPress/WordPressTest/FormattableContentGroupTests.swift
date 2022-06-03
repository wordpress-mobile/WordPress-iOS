import XCTest
@testable import WordPress

final class FormattableContentGroupTests: CoreDataTestCase {
    private var subject: FormattableContentGroup?
    private var utility: NotificationUtility!

    private struct Constants {
        static let kind: FormattableContentGroup.Kind = .activity
    }

    override func setUpWithError() throws {
        utility = NotificationUtility(coreDataStack: contextManager)
        subject = FormattableContentGroup(blocks: [try mockContent()], kind: Constants.kind)
    }

    override func tearDown() {
        subject = nil
        utility = nil
    }

    func testKindRemainsAsInitialised() {
        XCTAssertEqual(subject?.kind, Constants.kind)
    }

    func testBlocksRemainAsInitialised() throws {
        let groupBlocks = subject?.blocks as? [FormattableTextContent]
        let mockBlocks = [try mockContent()]

        /// Compare by the blocks' text
        let groupBlocksText = groupBlocks!.map { $0.text }
        let mockBlocksText = mockBlocks.map { $0.text }

        XCTAssertEqual(groupBlocksText, mockBlocksText)
    }

    func testBlockOfKindReturnsExpectation() throws {
        let obtainedBlock: FormattableTextContent? = subject?.blockOfKind(.text)
        let obtainedBlockText = obtainedBlock?.text

        let mockText = try mockContent().text

        XCTAssertEqual(obtainedBlockText, mockText)
    }

    func testBlockOfKindReturnsNilWhenNotFound() {
        let obtainedBlock: FormattableTextContent? = subject?.blockOfKind(.image)

        XCTAssertNil(obtainedBlock)
    }

    private func mockContent() throws -> FormattableTextContent {
        let text = try mockActivity()["text"] as? String ?? ""
        return FormattableTextContent(text: text, ranges: [], actions: [])
    }

    private func mockActivity() throws -> JSONObject {
        return try JSONObject(fromFileNamed: "activity-log-activity-content.json")
    }

}
