import XCTest
@testable import WordPress

class GutenbergCoverUploadProcessorTests: XCTestCase {

    let postContent = """
    <!-- wp:cover {"url":"file:///usr/tmp/-1175513456.jpg","id":-1175513456} -->
    <div class="wp-block-cover has-background-dim" style="background-image:url(file:///usr/tmp/-1175513456.jpg)"><div class="wp-block-cover__inner-container">
    <!-- wp:paragraph {"align":"center","placeholder":"Write title…"} -->
    <p class="has-text-align-center"></p>
    <!-- /wp:paragraph -->
    </div></div>
    <!-- /wp:cover -->
    """

    let postResultContent = """
    <!-- wp:cover {"id":456,"url":"http:\\/\\/www.wordpress.com\\/logo.jpg"} -->
    <div class="wp-block-cover has-background-dim" style="background-image:url(http://www.wordpress.com/logo.jpg)"><div class="wp-block-cover__inner-container">
    <!-- wp:paragraph {"align":"center","placeholder":"Write title…"} -->
    <p class="has-text-align-center"></p>
    <!-- /wp:paragraph -->
    </div></div>
    <!-- /wp:cover -->
    """

    func testCoverBlockProcessor() {
        let gutenbergMediaUploadID = Int32(-1175513456)
        let mediaID = 456
        let remoteURLStr = "http://www.wordpress.com/logo.jpg"

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

}
