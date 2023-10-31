import XCTest
@testable import WordPress

final class NotificationActionParserTest: XCTestCase {
    private let payload = [
        "approve-comment": 1,
        "spam-comment": 0,
        "edit-comment": 1,
        "trash-comment": 0,
        "replyto-comment": 1
    ] as [String: AnyObject]

    private var subject: NotificationActionParser?

    override func setUp() {
        super.setUp()
        subject = NotificationActionParser()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testFirstParsedActionIsApproveComment() {
        guard let firstAction = firstAction() else {
            XCTFail()
            return
        }

        XCTAssertEqual(firstAction.identifier, ApproveComment.commandIdentifier())
    }

    func testFirstParsedActionIsOn() {
        guard let firstAction = firstAction() else {
            XCTFail()
            return
        }

        XCTAssertTrue(firstAction.on)
    }

    func testSecondParsedActionIsEditComment() {
        guard let secondAction = secondAction() else {
            XCTFail()
            return
        }

        XCTAssertEqual(secondAction.identifier, EditComment.commandIdentifier())
    }

    func testSecondParsedActionIsOn() {
        guard let secondAction = secondAction() else {
            XCTFail()
            return
        }

        XCTAssertTrue(secondAction.on)
    }

    func testThirdParsedActionIsSpamComment() {
        guard let thirdAction = thirdAction() else {
            XCTFail()
            return
        }

        XCTAssertEqual(thirdAction.identifier, MarkAsSpam.commandIdentifier())
    }

    func testThirdParsedActionIsOff() {
        guard let thirdAction = thirdAction() else {
            XCTFail()
            return
        }

        XCTAssertFalse(thirdAction.on)
    }

    func testFourthParsedActionIsReplyComment() {
        guard let fourthAction = fourthAction() else {
            XCTFail()
            return
        }

        XCTAssertEqual(fourthAction.identifier, ReplyToComment.commandIdentifier())
    }

    func testFourthParsedActionIsOn() {
        guard let fourthAction = fourthAction() else {
            XCTFail()
            return
        }

        XCTAssertTrue(fourthAction.on)
    }

    func testFifthParsedActionIsTrashComment() {
        guard let fifthAction = fifthAction() else {
            XCTFail()
            return
        }

        XCTAssertEqual(fifthAction.identifier, TrashComment.commandIdentifier())
    }

    func testFifthParsedActionIsOff() {
        guard let fifthAction = fifthAction() else {
            XCTFail()
            return
        }

        XCTAssertFalse(fifthAction.on)
    }

    private func firstAction() -> FormattableContentActionCommand? {
        return action(at: 0)
    }

    private func secondAction() -> FormattableContentActionCommand? {
        return action(at: 1)
    }

    private func thirdAction() -> FormattableContentActionCommand? {
        return action(at: 2)
    }

    private func fourthAction() -> FormattableContentActionCommand? {
        return action(at: 3)
    }

    private func fifthAction() -> FormattableContentActionCommand? {
        return action(at: 4)
    }

    private func action(at: Int) -> FormattableContentActionCommand? {
        guard let actions = subject?.parse(payload) else {
            return nil
        }

        return actions.sorted(by: { lhs, rhs -> Bool in
            return lhs.identifier < rhs.identifier
        })[at].command
    }
}
