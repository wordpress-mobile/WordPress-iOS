import Foundation
import XCTest
@testable import WordPress

class GutenbergVideoUploadProcessorTests: XCTestCase {

    let postContent = """
<!-- wp:video {"id":-181231834} -->
<figure class="wp-block-video"><video controls src="file://tmp.mp4"></video></figure>
<!-- /wp:video -->
"""

    let postResultContent = """
<!-- wp:video {"id":100} -->
<figure class="wp-block-video"><video controls src="http://www.wordpress.com/video.mp4"></video></figure>
<!-- /wp:video -->
"""

    func testVideoBlockProcessor() {
        let gutenbergMediaUploadID = Int32(-181231834)
        let mediaID = 100
        let remoteURLStr = "http://www.wordpress.com/video.mp4"

        let gutenbergVideoUploadProcessor = GutenbergVideoUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        let resultContent = gutenbergVideoUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

    let postMediaBlockContent = """
    <!-- wp:media-text {"mediaId":-181231834,"mediaType":"video"} -->
    <div class="wp-block-media-text alignwide"><figure class="wp-block-media-text__media"><video controls src="file://tmp.mp4"></video></figure><div class="wp-block-media-text__content"><!-- wp:paragraph {"placeholder":"Content…","fontSize":"large"} -->
    <p class="has-large-font-size"></p>
    <!-- /wp:paragraph --></div></div>
    <!-- /wp:media-text -->
    """

    let postMediaBlockResultContent = """
    <!-- wp:media-text {"mediaId":100,"mediaType":"video"} -->
    <div class="wp-block-media-text alignwide"><figure class="wp-block-media-text__media"><video controls src="http://www.wordpress.com/video.mp4"></video></figure><div class="wp-block-media-text__content"><!-- wp:paragraph {"placeholder":"Content…","fontSize":"large"} -->
    <p class="has-large-font-size"></p>
    <!-- /wp:paragraph --></div></div>
    <!-- /wp:media-text -->
    """

    func testMediaTextBlockProcessor() {
        let gutenbergMediaUploadID = Int32(-181231834)
        let mediaID = 100
        let remoteURLStr = "http://www.wordpress.com/video.mp4"

        let gutenbergVideoUploadProcessor = GutenbergVideoUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        let resultContent = gutenbergVideoUploadProcessor.process(postMediaBlockContent)

        XCTAssertEqual(resultContent, postMediaBlockResultContent, "Post content should be updated correctly")
    }

    let postMediaBlockReversedAttributesContent = """
    <!-- wp:media-text {"mediaType":"video", "mediaId":-181231834} -->
    <div class="wp-block-media-text alignwide"><figure class="wp-block-media-text__media"><video controls src="file://tmp.mp4"></video></figure><div class="wp-block-media-text__content"><!-- wp:paragraph {"placeholder":"Content…","fontSize":"large"} -->
    <p class="has-large-font-size"></p>
    <!-- /wp:paragraph --></div></div>
    <!-- /wp:media-text -->
    """

    let postMediaBlockReversedAttributesResultContent = """
    <!-- wp:media-text {"mediaId":100,"mediaType":"video"} -->
    <div class="wp-block-media-text alignwide"><figure class="wp-block-media-text__media"><video controls src="http://www.wordpress.com/video.mp4"></video></figure><div class="wp-block-media-text__content"><!-- wp:paragraph {"placeholder":"Content…","fontSize":"large"} -->
    <p class="has-large-font-size"></p>
    <!-- /wp:paragraph --></div></div>
    <!-- /wp:media-text -->
    """

    func testMediaTextBlockReversedAttributesProcessor() {
        let gutenbergMediaUploadID = Int32(-181231834)
        let mediaID = 100
        let remoteURLStr = "http://www.wordpress.com/video.mp4"

        let gutenbergVideoUploadProcessor = GutenbergVideoUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        let resultContent = gutenbergVideoUploadProcessor.process(postMediaBlockReversedAttributesContent)

        XCTAssertEqual(resultContent, postMediaBlockReversedAttributesResultContent, "Post content should be updated correctly")
    }

}
