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

    private func firstAction() -> FormattableContentActionCommand? {
        guard let actions = subject?.parse(payload) else {
            return nil
        }

        return actions.first?.command
    }

    private func secondAction() -> FormattableContentActionCommand? {
        guard let actions = subject?.parse(payload) else {
            return nil
        }

        return actions[1].command
    }

    private func thirdAction() -> FormattableContentActionCommand? {
        guard let actions = subject?.parse(payload) else {
            return nil
        }

        return actions[2].command
    }
}
