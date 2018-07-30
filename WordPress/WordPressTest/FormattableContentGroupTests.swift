import XCTest
@testable import WordPress

final class FormattableContentGroupTests: XCTestCase {
    private let contextManager = TestContextManager()
    private var subject: FormattableContentGroup?
    private let utility = NotificationUtility()

    private struct Constants {
        static let kind: FormattableContentGroup.Kind = .activity
    }

    override func setUp() {
        super.setUp()
        utility.setUp()
        ContextManager.overrideSharedInstance(nil)
        subject = FormattableContentGroup(blocks: [mockContent()], kind: Constants.kind)
    }

    override func tearDown() {
        utility.tearDown()
        subject = nil
        ContextManager.overrideSharedInstance(nil)
        super.tearDown()
    }

    func testKindRemainsAsInitialised() {
        XCTAssertEqual(subject?.kind, Constants.kind)
    }

    func testBlocksRemainAsInitialised() {
        let groupBlocks = subject?.blocks as? [FormattableTextContent]
        let mockBlocks = [mockContent()]

        /// Compare by the blocks' text
        let groupBlocksText = groupBlocks!.map { $0.text }
        let mockBlocksText = mockBlocks.map { $0.text }

        XCTAssertEqual(groupBlocksText, mockBlocksText)
    }

    func testBlockOfKindReturnsExpectation() {
        let obtainedBlock: FormattableTextContent? = subject?.blockOfKind(.text)
        let obtainedBlockText = obtainedBlock?.text

        let mockText = mockContent().text

        XCTAssertEqual(obtainedBlockText, mockText)
    }

    func testBlockOfKindReturnsNilWhenNotFound() {
        let obtainedBlock: FormattableTextContent? = subject?.blockOfKind(.image)

        XCTAssertNil(obtainedBlock)
    }

    private func mockContent() -> FormattableTextContent {
        let text = mockActivity()["text"] as? String ?? ""
        return FormattableTextContent(text: text, ranges: [], actions: [])
    }

    private func mockActivity() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-activity-content.json")
    }

    private func getDictionaryFromFile(named fileName: String) -> [String: AnyObject] {
        return contextManager.object(withContentOfFile: fileName) as! [String: AnyObject]
    }
}
