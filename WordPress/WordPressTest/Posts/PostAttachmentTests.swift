import XCTest
import Aztec

@testable import WordPress

class MockAttachmentDelegate: TextViewAttachmentDelegate {

    func textView(_ textView: TextView, attachment: NSTextAttachment, imageAt url: URL, onSuccess success: @escaping (UIImage) -> Void, onFailure failure: @escaping () -> Void) {
        success(UIImage())
    }

    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL? {
        return URL(string: "http://someExampleImage.jpg")
    }

    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage {
        return UIImage()
    }

    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment) {
    }

    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint) {
    }

    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint) {
    }
}

class PostAttachmentTests: XCTestCase {

    func testIfAltValueWasAddedToImageAttachment() {
        let prefixString = "Image with alt: "
        let imageName = "someExampleImage.jpg"
        let altValue = "additional alt"

        let richTextView = TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: UIImage())
        let delegate = MockAttachmentDelegate()
        richTextView.textAttachmentDelegate = delegate
        richTextView.attributedText = NSAttributedString(string: prefixString)
        let attachment = richTextView.replaceWithImage(at: richTextView.selectedRange,
                                                       sourceURL: URL(string: imageName)!,
                                                       placeHolderImage: UIImage())

        let expect = expectation(description: "Alt Value has been updated")

        let controller = AztecAttachmentViewController()
        controller.attachment = attachment
        controller.alt = altValue
        controller.onUpdate = { (_, _, _, alt, _) in
            richTextView.edit(attachment) { updated in
                if let alt = alt {
                    updated.alt = alt
                }
                expect.fulfill()
            }
        }
        controller.handleDoneButtonTapped(sender: UIBarButtonItem())

        waitForExpectations(timeout: 1, handler: nil)

        let html = richTextView.getHTML()
        let expected = "<p>\(prefixString)<img src=\"\(imageName)\" alt=\"\(altValue)\"></p>"
        XCTAssertEqual(html, expected)
    }

    func testIfAltValueWasLeftEmptyForImageAttachment() {
        let prefixString = "Image without alt: "
        let imageName = "someExampleImage.jpg"
        let altValue = ""

        let richTextView = TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: UIImage())
        let delegate = MockAttachmentDelegate()
        richTextView.textAttachmentDelegate = delegate
        richTextView.attributedText = NSAttributedString(string: prefixString)
        let attachment = richTextView.replaceWithImage(at: richTextView.selectedRange,
                                                       sourceURL: URL(string: imageName)!,
                                                       placeHolderImage: UIImage())

        let expect = expectation(description: "AztecAttachmentViewController did finish updating")

        let controller = AztecAttachmentViewController()
        controller.attachment = attachment
        controller.alt = altValue
        controller.onUpdate = { (_, _, _, alt, _) in
            richTextView.edit(attachment) { updated in
                if let alt = alt {
                    updated.alt = alt
                }
                expect.fulfill()
            }
        }
        controller.handleDoneButtonTapped(sender: UIBarButtonItem())

        waitForExpectations(timeout: 1, handler: nil)

        let html = richTextView.getHTML()
        let expected = "<p>\(prefixString)<img src=\"\(imageName)\"></p>"
        XCTAssertEqual(html, expected)
    }

    func testIfLinkURLValueWasAddedToImageAttachment() {
        let prefixString = "Image with link: "
        let imageName = "someExampleImage.jpg"
        let linkURLValue = URL(string: "https://wordpress.com/")!

        let richTextView = TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: UIImage())
        let delegate = MockAttachmentDelegate()
        richTextView.textAttachmentDelegate = delegate
        richTextView.attributedText = NSAttributedString(string: prefixString)
        let attachment = richTextView.replaceWithImage(at: richTextView.selectedRange,
                                                       sourceURL: URL(string: imageName)!,
                                                       placeHolderImage: UIImage())

        let expect = expectation(description: "Link URL value has been updated")

        let controller = AztecAttachmentViewController()
        controller.attachment = attachment
        controller.linkURL = linkURLValue
        controller.onUpdate = { (_, _, linkURL, _, _) in
            if let url = linkURL, let range = richTextView.textStorage.ranges(forAttachment: attachment).first {
                richTextView.setLink(url, inRange: range)
            }
            expect.fulfill()
        }
        controller.handleDoneButtonTapped(sender: UIBarButtonItem())

        waitForExpectations(timeout: 1, handler: nil)

        let html = richTextView.getHTML()
        let expected = "<p>Image with link: <a href=\"https://wordpress.com/\"><img src=\"\(imageName)\"></a></p>"

        XCTAssertEqual(html, expected)
    }
}
