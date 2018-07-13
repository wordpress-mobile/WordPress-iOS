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

    func testSecondParsedActionIsSpamComment() {
        guard let secondAction = secondAction() else {
            XCTFail()
            return
        }

        XCTAssertEqual(secondAction.identifier, MarkAsSpam.commandIdentifier())
    }

    func testSecondParsedActionIsOff() {
        guard let secondAction = secondAction() else {
            XCTFail()
            return
        }

        XCTAssertFalse(secondAction.on)
    }

    func testThirdParsedActionIsEditComment() {
        guard let thirdAction = thirdAction() else {
            XCTFail()
            return
        }

        XCTAssertEqual(thirdAction.identifier, EditComment.commandIdentifier())
    }

    func testThirdParsedActionIsOn() {
        guard let thirdAction = thirdAction() else {
            XCTFail()
            return
        }

        XCTAssertTrue(thirdAction.on)
    }

    func testFourthParsedActionIsTrashComment() {
        guard let fourthAction = fourthAction() else {
            XCTFail()
            return
        }

        XCTAssertEqual(fourthAction.identifier, TrashComment.commandIdentifier())
    }

    func testFourthParsedActionIsOff() {
        guard let fourthAction = fourthAction() else {
            XCTFail()
            return
        }

        XCTAssertFalse(fourthAction.on)
    }

    func testFifthParsedActionIsReplyToComment() {
        guard let fifthAction = fifthAction() else {
            XCTFail()
            return
        }

        XCTAssertEqual(fifthAction.identifier, ReplyToComment.commandIdentifier())
    }

    func testFifthParsedActionIsOn() {
        guard let fifthAction = fifthAction() else {
            XCTFail()
            return
        }

        XCTAssertTrue(fifthAction.on)
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

        return actions[at].command
    }
}
