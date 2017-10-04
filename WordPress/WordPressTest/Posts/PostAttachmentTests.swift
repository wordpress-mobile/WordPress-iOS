//
//  PostAttachmentTests.swift
//  WordPressTest
//
//  Created by Evangelos Sismanidis on 04.10.17.
//  Copyright © 2017 WordPress. All rights reserved.
//

import XCTest
import Aztec

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

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testIfAltValueWasAddedToImageAttachment() {
        let richTextView = TextView(defaultFont: UIFont(), defaultMissingImage: UIImage())
        let delegate = MockAttachmentDelegate()
        richTextView.textAttachmentDelegate = delegate
        richTextView.attributedText = NSAttributedString(string: "Image: ")
        let attachment = richTextView.replaceWithImage(at: richTextView.selectedRange,
                                                       sourceURL: URL(string: "someExampleImage.jpg")!,
                                                       placeHolderImage: UIImage())
        attachment.extraAttributes["alt"] = "alt"
        let html = richTextView.getHTML()
        XCTAssert(html == "<p>Image: <img src=\"someExampleImage.jpg\" alt=\"alt\"></p>")
    }
    
}

