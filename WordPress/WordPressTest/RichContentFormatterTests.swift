import XCTest
@testable import WordPress



class RichContentFormatterTests: XCTestCase
{

    func testRemoveInlineStyles() {
        let str = "<p>test</p><p>test</p>"
        let styleStr = "<p style=\"background-color:#fff;\">test</p><p style=\"background-color:#fff;\">test</p>"
        let sanitizedStr = RichContentFormatter.removeInlineStyles(styleStr)
        XCTAssertTrue(str == sanitizedStr, "The inline styles were not removed.")
    }


    func testRemoveForbiddenTags() {
        let str = "<p>test</p><p>test</p>"
        let styleStr = "<script>alert();</script><style>body{color:#000;}</style><p>test</p><script>alert();</script><style>body{color:#000;}</style><p>test</p><script>alert();</script><style>body{color:#000;}</style>"
        let sanitizedStr = RichContentFormatter.removeForbiddenTags(styleStr)
        XCTAssertTrue(str == sanitizedStr, "The inline styles were not removed.")
    }


    func testNormalizeParagraphs() {
        let str = "<p>test</p><p>test</p>"
        let styleStr = "<div><p>test</p></div>\n<p><div>test</div></p>\n"
        let sanitizedStr = RichContentFormatter.normalizeParagraphs(styleStr)
        XCTAssertTrue(str == sanitizedStr, "The inline styles were not removed.")
    }

    func testResizeGalleryImageURLsForContentPublic() {
        guard
            let path = NSBundle(forClass: self.dynamicType).pathForResource("gallery-reader-post-public", ofType: "json"),
            let data = NSData(contentsOfFile: path),
            let postDict = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
            let content = postDict.stringForKey("content"),
            let window = UIApplication.sharedApplication().keyWindow else {
                XCTFail()
                return
        }

        let resultContent = RichContentFormatter.resizeGalleryImageURL(content, isPrivateSite: false)
        let imageSize = window.frame.size
        let scale = UIScreen.mainScreen().scale
        let scaledSize = CGSizeApplyAffineTransform(imageSize, CGAffineTransformMakeScale(scale, scale))

        // Verify that the image source was updated with a Photon-friendly sized URL
        let sourceStr = "src=\"https://lanteanartest.files.wordpress.com/2016/07/image217.png?w=1024&#038;h=1365\""
        XCTAssertTrue(content.containsString(sourceStr))
        XCTAssertFalse(resultContent.containsString(sourceStr))
        let expectedURL = "src=\"https://i0.wp.com/lanteanartest.files.wordpress.com/2016/07/image217.png?quality=80&resize=\(Int(scaledSize.width)),\(Int(scaledSize.height))&ssl=1\""
        XCTAssertTrue(resultContent.containsString(expectedURL))
    }


    func testResizeGalleryImageURLsForContentPrivate() {
        guard
            let path = NSBundle(forClass: self.dynamicType).pathForResource("gallery-reader-post-private", ofType: "json"),
            let data = NSData(contentsOfFile: path),
            let postDict = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
            let content = postDict.stringForKey("content"),
            let window = UIApplication.sharedApplication().keyWindow else {
                XCTFail()
                return
        }

        let resultContent = RichContentFormatter.resizeGalleryImageURL(content, isPrivateSite: true)
        let imageSize = window.frame.size
        let scale = UIScreen.mainScreen().scale
        let scaledSize = CGSizeApplyAffineTransform(imageSize, CGAffineTransformMakeScale(scale, scale))

        // Verify that the image source was updated with a Photon-friendly sized URL
        let sourceStr = "src=\"https://picklessaltyporkvonhausen.files.wordpress.com/2016/07/img_8961.jpg?w=181&#038;h=135&#038;crop=1\""
        XCTAssertTrue(content.containsString(sourceStr))
        XCTAssertFalse(resultContent.containsString(sourceStr))
        let expectedURL = "src=\"https://picklessaltyporkvonhausen.files.wordpress.com/2016/07/img_8961.jpg?h=\(Int(scaledSize.height))&w=\(Int(scaledSize.width))\""
        XCTAssertTrue(resultContent.containsString(expectedURL))
    }


    func testResizeGalleryImageURLsForContentEmptyString() {
        XCTAssertTrue("" == RichContentFormatter.resizeGalleryImageURL("", isPrivateSite: false))
    }
}
