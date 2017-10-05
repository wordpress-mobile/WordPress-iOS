import XCTest
import Aztec

@testable import WordPress

class MockAttachmentDelegate: TextViewAttachmentDelegate {

    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        success(UIImage())
    }

    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL {
        return URL(string: "http://someExampleImage.jpg")!
    }

    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return UIImage()
    }

    func textView(_ textView: TextView, deletedAttachmentWith attachmentID: String) {
    }

    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
    }

    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
    }
}

class PostAttachmentTests: XCTestCase {

    private let richTextView = TextView(defaultFont: UIFont(), defaultMissingImage: UIImage())
    private let delegate = MockAttachmentDelegate()

    override func setUp() {
        super.setUp()
        richTextView.textAttachmentDelegate = delegate
    }

    override func tearDown() {
        richTextView.textAttachmentDelegate = nil
        super.tearDown()
    }

    func testIfAltValueWasAddedToImageAttachment() {
        richTextView.attributedText = NSAttributedString(string: "Image with alt: ")
        let attachment = richTextView.replaceWithImage(at: richTextView.selectedRange,
                                                       sourceURL: URL(string: "someExampleImage.jpg")!,
                                                       placeHolderImage: UIImage())

        let expect = expectation(description: "Alt Value has been updated")

        let controller = AztecAttachmentViewController()
        controller.attachment = attachment
        controller.alt = "alt"
        controller.onUpdate = { [weak self] (_, _, alt) in
            self?.richTextView.edit(attachment) { updated in
                if let alt = alt {
                    updated.extraAttributes["alt"] = alt
                }
                expect.fulfill()
            }
        }
        controller.handleDoneButtonTapped(sender: UIBarButtonItem())

        waitForExpectations(timeout: 1, handler: nil)

        let html = richTextView.getHTML()
        XCTAssert(html == "<p>Image with alt: <img src=\"someExampleImage.jpg\" alt=\"alt\"></p>")
    }

    func testIfAltValueWasLeftEmptyForImageAttachment() {
        richTextView.attributedText = NSAttributedString(string: "Image with alt: ")
        let attachment = richTextView.replaceWithImage(at: richTextView.selectedRange,
                                                       sourceURL: URL(string: "someExampleImage.jpg")!,
                                                       placeHolderImage: UIImage())

        let expect = expectation(description: "AztecAttachmentViewController did finish updating")

        let controller = AztecAttachmentViewController()
        controller.attachment = attachment
        controller.alt = ""
        controller.onUpdate = { [weak self] (_, _, alt) in
            self?.richTextView.edit(attachment) { updated in
                if let alt = alt {
                    updated.extraAttributes["alt"] = alt
                }
                expect.fulfill()
            }
        }
        controller.handleDoneButtonTapped(sender: UIBarButtonItem())

        waitForExpectations(timeout: 1, handler: nil)

        let html = richTextView.getHTML()
        XCTAssert(html == "<p>Image with alt: <img src=\"someExampleImage.jpg\"></p>")
    }
}
