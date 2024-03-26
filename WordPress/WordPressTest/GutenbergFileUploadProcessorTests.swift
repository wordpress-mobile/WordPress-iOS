import XCTest
@testable import WordPress

class GutenbergFileUploadProcessorTests: XCTestCase {

    let postContent = """
<!-- wp:file {"id":-1626352752,"href":"file://file.pdf"} -->
<div class="wp-block-file"><a href="file://file.pdf">dummy.pdf</a><a href="file://file.pdf" class="wp-block-file__button wp-element-button" download>Download</a></div>
<!-- /wp:file -->
"""

    let postResultContent = """
<!-- wp:file {"href":"http:\\/\\/www.wordpress.com\\/file.pdf","id":100} -->
<div class="wp-block-file"><a href="http://www.wordpress.com/file.pdf">dummy.pdf</a><a href="http://www.wordpress.com/file.pdf" class="wp-block-file__button wp-element-button" download>Download</a></div>
<!-- /wp:file -->
"""

    func testFileBlockProcessor() {
        let gutenbergMediaUploadID = Int32(-1626352752)
        let mediaID = 100
        let remoteURLStr = "http://www.wordpress.com/file.pdf"

        let gutenbergFilePostUploadProcessor = GutenbergFileUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)

        let parser = GutenbergContentParser(for: postContent)
        gutenbergFilePostUploadProcessor.process(parser.blocks)

        XCTAssertEqual(parser.html(), postResultContent, "Post content should be updated correctly")
    }
}
