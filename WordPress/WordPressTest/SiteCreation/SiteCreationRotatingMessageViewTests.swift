import XCTest
@testable import WordPress

class SiteCreationRotatingMessageViewTests: XCTestCase {
    private let testMessages = [
        "Test Message 1",
        "Test Message 2",
        "Test Message 3"
    ]

    private var rotatingMessageView: SiteCreationRotatingMessageView?

    override func setUp() {
        super.setUp()

        self.rotatingMessageView = SiteCreationRotatingMessageView(messages: testMessages,
                                                                   iconImage: UIImage())
    }

    override func tearDown() {
        self.rotatingMessageView = nil

        super.tearDown()
    }

    /// Test to make sure the statusLabel text and accesibility labels are being set correctly
    func testSiteCreationRotatingMessageView_StatusUpdate() {
        let message = "This is a test!"
        rotatingMessageView?.updateStatus(message: message)

        XCTAssertEqual(rotatingMessageView?.statusLabel.text, message)
    }

    /// Test to make sure the reset logic is working correctly
    func testSiteCreationRotatingMessageView_Reset() {
        rotatingMessageView?.reset()

        XCTAssertEqual(rotatingMessageView?.visibleIndex, 0)
        XCTAssertEqual(rotatingMessageView?.statusLabel.text, testMessages[0])
    }

    /// Test to make sure the start/stop animating methods create and teardown the timer
    func testSiteCreationRotatingMessageView_Animating() {
        rotatingMessageView?.startAnimating()
        XCTAssertNotNil(rotatingMessageView?.animationTimer)

        rotatingMessageView?.stopAnimating()
        XCTAssertNil(rotatingMessageView?.animationTimer)
    }

    /// Test to make sure the message rotation logic is working correctly
    func testSiteCreationRotatingMessageView_MessageRotation() {
        rotatingMessageView?.reset()
        rotatingMessageView?.updateStatusLabelWithNextMessage()

        XCTAssertEqual(rotatingMessageView?.visibleIndex, 1)
        XCTAssertEqual(rotatingMessageView?.statusLabel.text, testMessages[1])
    }

    /// Test to make sure when rotating through the messages we'll loop
    /// back around to 0 when we exceed the message count
    func testSiteCreationRotatingMessageView_OutOfBoundsMessageRotation() {
        rotatingMessageView?.reset() //visibleIndex should be: 0

        rotatingMessageView?.updateStatusLabelWithNextMessage() //visibleIndex should be: 1
        rotatingMessageView?.updateStatusLabelWithNextMessage() //visibleIndex should be: 2
        rotatingMessageView?.updateStatusLabelWithNextMessage() //visibleIndex should be: 0

        XCTAssertEqual(rotatingMessageView?.visibleIndex, 0)
        XCTAssertEqual(rotatingMessageView?.statusLabel.text, testMessages[0])
    }
}
