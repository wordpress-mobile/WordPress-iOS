import XCTest
@testable import WordPress

class GutenbergImgUploadProcessorTests: XCTestCase {

    let postContent = """
<!-- wp:image {"id":-181231834} -->
<figure class="wp-block-image"><img src="file://tmp/EC856C66-7B79-4631-9503-2FB9FF0E6C66.jpg" alt="" class="wp-image--181231834"/></figure>
<!-- /wp:image -->
"""

    let postResultContent = """
<!-- wp:image {"id":100} -->
<figure class="wp-block-image"><img src="http://www.wordpress.com/logo.jpg" alt="" class="wp-image-100"/></figure>
<!-- /wp:image -->
"""

    func testImgBlockProcessor() {
        let gutenbergMediaUploadID = Int32(-181231834)
        let mediaID = 100
        let remoteURLStr = "http://www.wordpress.com/logo.jpg"

        let gutenbergImgPostUploadProcessor = GutenbergImgUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        let resultContent = gutenbergImgPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

    let postMediaBlockContent = """
    <!-- wp:media-text {"mediaId":-181231834,"mediaType":"image"} -->
    <div class="wp-block-media-text alignwide"><figure class="wp-block-media-text__media"><img src="file://tmp/EC856C66-7B79-4631-9503-2FB9FF0E6C66.jpg" alt="" class="wp-image--181231834"/></figure><div class="wp-block-media-text__content"><!-- wp:paragraph {"placeholder":"Content…","fontSize":"large"} -->
    <p class="has-large-font-size"></p>
    <!-- /wp:paragraph --></div></div>
    <!-- /wp:media-text -->
    """

    let postMediaBlockResultContent = """
    <!-- wp:media-text {"mediaId":100,"mediaType":"image"} -->
    <div class="wp-block-media-text alignwide"><figure class="wp-block-media-text__media"><img src="http://www.wordpress.com/logo.jpg" alt="" class="wp-image-100"/></figure><div class="wp-block-media-text__content"><!-- wp:paragraph {"placeholder":"Content…","fontSize":"large"} -->
    <p class="has-large-font-size"></p>
    <!-- /wp:paragraph --></div></div>
    <!-- /wp:media-text -->
    """

    func testMediaTextBlockProcessor() {
        let gutenbergMediaUploadID = Int32(-181231834)
        let mediaID = 100
        let remoteURLStr = "http://www.wordpress.com/logo.jpg"

        let gutenbergImgPostUploadProcessor = GutenbergImgUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        let resultContent = gutenbergImgPostUploadProcessor.process(postMediaBlockContent)

        XCTAssertEqual(resultContent, postMediaBlockResultContent, "Post content should be updated correctly")
    }

}
