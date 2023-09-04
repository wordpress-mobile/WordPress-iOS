import Foundation
import XCTest
@testable import WordPress

class GutenbergVideoPressUploadProcessorTests: XCTestCase {

    let blockWithDefaultAttrsContent = """
    <!-- wp:videopress/video {"id":-181231834, "src":"file:///LocalFolder/181231834.mp4"} /-->
    """

    let blockWithDefaultAttrsResultContent = """
    <!-- wp:videopress/video {"guid":"AbCdE","id":100} /-->
    """

    func testVideoPressBlockWithDefaultAttrsProcessor() {
        let gutenbergMediaUploadID = Int32(-181231834)
        let mediaID = 100
        let videoPressGUID = "AbCdE"

        let gutenbergVideoPressUploadProcessor = GutenbergVideoPressUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, videoPressGUID: videoPressGUID)
        let resultContent = gutenbergVideoPressUploadProcessor.process(blockWithDefaultAttrsContent)

        XCTAssertEqual(resultContent, blockWithDefaultAttrsResultContent, "Post content should be updated correctly")
    }

    let blockWithAttrsContent = """
    <!-- wp:videopress/video {"autoplay":true,"controls":false,"description":"","id":-181231834,"loop":true,"muted":true,"playsinline":true,"poster":"https://test.files.wordpress.com/2022/02/265-5000x5000-1.jpeg","preload":"none","seekbarColor":"#abb8c3","seekbarLoadingColor":"#cf2e2e","seekbarPlayedColor":"#9b51e0","title":"Demo title","useAverageColor":false} /-->
    """

    let blockWithAttrsResultContent = """
    <!-- wp:videopress/video {"autoplay":true,"controls":false,"description":"","guid":"AbCdE","id":100,"loop":true,"muted":true,"playsinline":true,"poster":"https:\\/\\/test.files.wordpress.com\\/2022\\/02\\/265-5000x5000-1.jpeg","preload":"none","seekbarColor":"#abb8c3","seekbarLoadingColor":"#cf2e2e","seekbarPlayedColor":"#9b51e0","title":"Demo title","useAverageColor":false} /-->
    """

    func testVideoPressBlockWithAttrsProcessor() {
        let gutenbergMediaUploadID = Int32(-181231834)
        let mediaID = 100
        let videoPressGUID = "AbCdE"

        let gutenbergVideoPressUploadProcessor = GutenbergVideoPressUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, videoPressGUID: videoPressGUID)
        let resultContent = gutenbergVideoPressUploadProcessor.process(blockWithAttrsContent)

        XCTAssertEqual(resultContent, blockWithAttrsResultContent, "Post content should be updated correctly")
    }

    let blockWithEmojiContent = """
    <!-- wp:videopress/video {"autoplay":true,"controls":false,"description":"","id":-181231834,"loop":true,"muted":true,"playsinline":true,"poster":"https://test.files.wordpress.com/2022/02/265-5000x5000-1.jpeg","preload":"none","seekbarColor":"#abb8c3","seekbarLoadingColor":"#cf2e2e","seekbarPlayedColor":"#9b51e0","title":"Demo title 🙂","useAverageColor":false} /-->
    """

    let blockWithEmojiResultContent = """
    <!-- wp:videopress/video {"autoplay":true,"controls":false,"description":"","guid":"AbCdE","id":100,"loop":true,"muted":true,"playsinline":true,"poster":"https:\\/\\/test.files.wordpress.com\\/2022\\/02\\/265-5000x5000-1.jpeg","preload":"none","seekbarColor":"#abb8c3","seekbarLoadingColor":"#cf2e2e","seekbarPlayedColor":"#9b51e0","title":"Demo title 🙂","useAverageColor":false} /-->
    """

    func testVideoPressBlockWithEmojiProcessor() {
        let gutenbergMediaUploadID = Int32(-181231834)
        let mediaID = 100
        let videoPressGUID = "AbCdE"

        let gutenbergVideoPressUploadProcessor = GutenbergVideoPressUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, videoPressGUID: videoPressGUID)
        let resultContent = gutenbergVideoPressUploadProcessor.process(blockWithEmojiContent)

        XCTAssertEqual(resultContent, blockWithEmojiResultContent, "Post content should be updated correctly")
    }
}
