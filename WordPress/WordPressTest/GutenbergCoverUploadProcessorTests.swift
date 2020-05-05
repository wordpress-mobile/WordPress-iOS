import XCTest
@testable import WordPress

class GutenbergCoverUploadProcessorTests: XCTestCase {

    let paragraphBlock = """
    <!-- wp:paragraph {"align":"center","placeholder":"Write title…"} -->
    <p class="has-text-align-center"></p>
    <!-- /wp:paragraph -->
    """

    let gutenbergMediaUploadID = Int32(-1175513456)
    let mediaID = 987
    let remoteURLStr = "http://www.wordpress.com/logo.jpg"

    func localCoverBlock(innerBlock: String, mediaID: Int32) -> String {
        return """
        <!-- wp:cover {"url":"file:///usr/tmp/local.jpg","id":\(mediaID)} -->
        <div class="wp-block-cover has-background-dim" style="background-image:url(file:///usr/tmp/local.jpg)"><div class="wp-block-cover__inner-container">
        \(innerBlock)
        </div></div>
        <!-- /wp:cover -->
        """
    }

    func uploadedCoverBlock(innerBlock: String, mediaID: Int) -> String {
        return """
        <!-- wp:cover {"id":\(mediaID),"url":"http:\\/\\/www.wordpress.com\\/logo.jpg"} -->
        <div class="wp-block-cover has-background-dim" style="background-image:url(http://www.wordpress.com/logo.jpg)"><div class="wp-block-cover__inner-container">
        \(innerBlock)
        </div></div>
        <!-- /wp:cover -->
        """
    }

    func testCoverBlockProcessor() {

        let postContent = localCoverBlock(innerBlock: paragraphBlock, mediaID: gutenbergMediaUploadID)
        let postResultContent = uploadedCoverBlock(innerBlock: paragraphBlock, mediaID: mediaID)

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

    func testMultipleCoverBlocksProcessor() {

        let coverBlock1 = uploadedCoverBlock(innerBlock: paragraphBlock, mediaID: 123)
        let localBlock = localCoverBlock(innerBlock: paragraphBlock, mediaID: gutenbergMediaUploadID)
        let coverBlock2 = uploadedCoverBlock(innerBlock: paragraphBlock, mediaID: 456)

        let postContent = "\(coverBlock1) \(localBlock) \(coverBlock2)"

        let uploadedBlock = uploadedCoverBlock(innerBlock: paragraphBlock, mediaID: mediaID)
        let postResultContent = "\(coverBlock1) \(uploadedBlock) \(coverBlock2)"

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

    func testNestedCoverBlockProcessor() {

        let nestedBlock = localCoverBlock(innerBlock: paragraphBlock, mediaID: gutenbergMediaUploadID)
        let postContent = uploadedCoverBlock(innerBlock: nestedBlock, mediaID: 123)

        let uploadedNestedBlock = uploadedCoverBlock(innerBlock: paragraphBlock, mediaID: mediaID)
        let postResultContent = uploadedCoverBlock(innerBlock: uploadedNestedBlock, mediaID: 123)

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

    func testDeepNestedCoverBlockProcessor() {

        let nestedBlock = localCoverBlock(innerBlock: paragraphBlock, mediaID: gutenbergMediaUploadID)
        let innerBlock = uploadedCoverBlock(innerBlock: nestedBlock, mediaID: 457)
        let postContent = uploadedCoverBlock(innerBlock: innerBlock, mediaID: 123)

        let uploadedNestedBlock = uploadedCoverBlock(innerBlock: paragraphBlock, mediaID: mediaID)
        let innerBlockWithUploadedBlock = uploadedCoverBlock(innerBlock: uploadedNestedBlock, mediaID: 457)
        let postResultContent = uploadedCoverBlock(innerBlock: innerBlockWithUploadedBlock, mediaID: 123)

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

    func testUpdateOuterCoverBlockProcessor() {

        let innerBlock = uploadedCoverBlock(innerBlock: paragraphBlock, mediaID: 457)
        let postContent = localCoverBlock(innerBlock: innerBlock, mediaID: gutenbergMediaUploadID)

        let postResultContent = uploadedCoverBlock(innerBlock: innerBlock, mediaID: mediaID)

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

    func testCoverBlockProcessorWithOtherAttributes() {

        let postContentWithOtherAttributes = """
           <!-- wp:cover {"url":"file:///usr/tmp/-1175513456.jpg","id":\(gutenbergMediaUploadID)} -->
           <div class="wp-block-cover has-background-dim" style="color:black;background-image:url(file:///usr/tmp/-1175513456.jpg);align:center"><div class="wp-block-cover__inner-container">
           \(paragraphBlock)
           </div></div>
           <!-- /wp:cover -->
           """

        let postResultContentWithOtherAttributes = """
           <!-- wp:cover {"id":\(mediaID),"url":"http:\\/\\/www.wordpress.com\\/logo.jpg"} -->
           <div class="wp-block-cover has-background-dim" style="color:black;background-image:url(http://www.wordpress.com/logo.jpg);align:center"><div class="wp-block-cover__inner-container">
           \(paragraphBlock)
           </div></div>
           <!-- /wp:cover -->
           """

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContentWithOtherAttributes)

        XCTAssertEqual(resultContent, postResultContentWithOtherAttributes, "Post content should be updated correctly")
    }
}
