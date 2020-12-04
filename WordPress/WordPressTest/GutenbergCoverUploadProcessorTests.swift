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
    let remoteImgURLStr = "http://www.wordpress.com/logo.jpg"
    let remoteVideoURLStr = "http://www.wordpress.com/test.mov"

    func localImgCoverBlock(innerBlock: String, mediaID: Int32) -> String {
        return """
        <!-- wp:cover {"url":"file:///usr/tmp/local.jpg","id":\(mediaID)} -->
        <div class="wp-block-cover has-background-dim" style="background-image:url(file:///usr/tmp/local.jpg)"><div class="wp-block-cover__inner-container">
        \(innerBlock)
        </div></div>
        <!-- /wp:cover -->
        """
    }

    func uploadedImgCoverBlock(innerBlock: String, mediaID: Int) -> String {
        return """
        <!-- wp:cover {"id":\(mediaID),"url":"http:\\/\\/www.wordpress.com\\/logo.jpg"} -->
        <div class="wp-block-cover has-background-dim" style="background-image:url(\(remoteImgURLStr))"><div class="wp-block-cover__inner-container">
        \(innerBlock)
        </div></div>
        <!-- /wp:cover -->
        """
    }

    func localVideoCoverBlock(innerBlock: String, mediaID: Int32) -> String {
        return """
        <!-- wp:cover {"url":"file:///usr/tmp/-1175513456.mov","id":\(mediaID),"backgroundType":"video"} -->
        <div class="wp-block-cover has-background-dim"><video class="wp-block-cover__video-background" autoplay muted loop playsinline src="file:///usr/tmp/-1175513456.mov"></video><div class="wp-block-cover__inner-container">
        \(innerBlock)
        </div></div>
        <!-- /wp:cover -->
        """
    }

    func uploadedVideoCoverBlock(innerBlock: String, mediaID: Int) -> String {
        return """
        <!-- wp:cover {"backgroundType":"video","id":\(mediaID),"url":"http:\\/\\/www.wordpress.com\\/test.mov"} -->
        <div class="wp-block-cover has-background-dim"><video class="wp-block-cover__video-background" autoplay muted loop playsinline src="\(remoteVideoURLStr)"></video><div class="wp-block-cover__inner-container">
        \(innerBlock)
        </div></div>
        <!-- /wp:cover -->
        """
    }

    func testCoverBlockProcessor() {

        let postContent = localImgCoverBlock(innerBlock: paragraphBlock, mediaID: gutenbergMediaUploadID)
        let postResultContent = uploadedImgCoverBlock(innerBlock: paragraphBlock, mediaID: mediaID)

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteImgURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

    func testMultipleCoverBlocksProcessor() {

        let coverBlock1 = uploadedImgCoverBlock(innerBlock: paragraphBlock, mediaID: 123)
        let localBlock = localImgCoverBlock(innerBlock: paragraphBlock, mediaID: gutenbergMediaUploadID)
        let coverBlock2 = uploadedImgCoverBlock(innerBlock: paragraphBlock, mediaID: 456)

        let postContent = "\(coverBlock1) \(localBlock) \(coverBlock2)"

        let uploadedBlock = uploadedImgCoverBlock(innerBlock: paragraphBlock, mediaID: mediaID)
        let postResultContent = "\(coverBlock1) \(uploadedBlock) \(coverBlock2)"

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteImgURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

    func testNestedCoverBlockProcessor() {

        let nestedBlock = localImgCoverBlock(innerBlock: paragraphBlock, mediaID: gutenbergMediaUploadID)
        let postContent = uploadedImgCoverBlock(innerBlock: nestedBlock, mediaID: 123)

        let uploadedNestedBlock = uploadedImgCoverBlock(innerBlock: paragraphBlock, mediaID: mediaID)
        let postResultContent = uploadedImgCoverBlock(innerBlock: uploadedNestedBlock, mediaID: 123)

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteImgURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

    func testDeepNestedCoverBlockProcessor() {

        let nestedBlock = localImgCoverBlock(innerBlock: paragraphBlock, mediaID: gutenbergMediaUploadID)
        let innerBlock = uploadedImgCoverBlock(innerBlock: nestedBlock, mediaID: 457)
        let postContent = uploadedImgCoverBlock(innerBlock: innerBlock, mediaID: 123)

        let uploadedNestedBlock = uploadedImgCoverBlock(innerBlock: paragraphBlock, mediaID: mediaID)
        let innerBlockWithUploadedBlock = uploadedImgCoverBlock(innerBlock: uploadedNestedBlock, mediaID: 457)
        let postResultContent = uploadedImgCoverBlock(innerBlock: innerBlockWithUploadedBlock, mediaID: 123)

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteImgURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResultContent, "Post content should be updated correctly")
    }

    func testUpdateOuterCoverBlockProcessor() {

        let innerBlock = uploadedImgCoverBlock(innerBlock: paragraphBlock, mediaID: 457)
        let postContent = localImgCoverBlock(innerBlock: innerBlock, mediaID: gutenbergMediaUploadID)

        let postResultContent = uploadedImgCoverBlock(innerBlock: innerBlock, mediaID: mediaID)

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteImgURLStr)
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

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteImgURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContentWithOtherAttributes)

        XCTAssertEqual(resultContent, postResultContentWithOtherAttributes, "Post content should be updated correctly")
    }

    func testVideoCoverBlockProcessor() {

        let postContent = localVideoCoverBlock(innerBlock: paragraphBlock, mediaID: gutenbergMediaUploadID)
        let postResult = uploadedVideoCoverBlock(innerBlock: paragraphBlock, mediaID: mediaID)

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteVideoURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResult, "Post content should be updated correctly")
    }

    func testImageCoverInVideoCoverBlockProcessor() {

        let imgCover = localImgCoverBlock(innerBlock: paragraphBlock, mediaID: gutenbergMediaUploadID)
        let postContent = uploadedVideoCoverBlock(innerBlock: imgCover, mediaID: 457)

        let uploadedImgCover = uploadedImgCoverBlock(innerBlock: paragraphBlock, mediaID: mediaID)
        let postResult = uploadedVideoCoverBlock(innerBlock: uploadedImgCover, mediaID: 457)

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteImgURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResult, "Post content should be updated correctly")
    }

    func testVideoCoverInImageCoverBlockProcessor() {

        let videoCover = localVideoCoverBlock(innerBlock: paragraphBlock, mediaID: gutenbergMediaUploadID)
        let postContent = uploadedImgCoverBlock(innerBlock: videoCover, mediaID: 457)

        let uploadedVideoCover = uploadedVideoCoverBlock(innerBlock: paragraphBlock, mediaID: mediaID)
        let postResult = uploadedImgCoverBlock(innerBlock: uploadedVideoCover, mediaID: 457)

        let gutenbergCoverPostUploadProcessor = GutenbergCoverUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, remoteURLString: remoteVideoURLStr)
        let resultContent = gutenbergCoverPostUploadProcessor.process(postContent)

        XCTAssertEqual(resultContent, postResult, "Post content should be updated correctly")
    }
}
