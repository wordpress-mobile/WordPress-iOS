import XCTest
@testable import WordPress

final class SupportChatBotViewModelTests: XCTestCase {
    private var sut: SupportChatBotViewModel!
    private var zendeskUtils: ZendeskUtilsSpy!

    override func setUpWithError() throws {
        try super.setUpWithError()
        zendeskUtils = ZendeskUtilsSpy()
        sut = SupportChatBotViewModel(zendeskUtils: zendeskUtils)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        zendeskUtils = nil
        sut = nil
    }

    func testContactSupport() {
        let messages: [SupportChatHistory.Message] = [
            .init(question: "I cannot login", answer: "Try turning the phone on and off"),
            .init(question: "It didn't work", answer: "Please contact support")
        ]
        let history = SupportChatHistory(messages: messages)

        let expectedDescription =
        """
        Jetpack Mobile Bot transcript:
        >
        Question:
        >
        I cannot login
        >
        Answer:
        >
        Try turning the phone on and off
        >
        Question:
        >
        It didn't work
        >
        Answer:
        >
        Please contact support
        """

        sut.contactSupport(including: history, in: UIViewController()) { _ in }

        XCTAssertEqual(zendeskUtils.description, expectedDescription)
        XCTAssertEqual(zendeskUtils.tags, ["DocsBot"])
    }
}

private class ZendeskUtilsSpy: ZendeskUtilsProtocol {
    var description: String?
    var tags: [String]?

    func createNewRequest(in viewController: UIViewController, description: String, tags: [String], completion: @escaping ZendeskNewRequestCompletion) {
        self.description = description
        self.tags = tags
    }
}
