import Foundation
import XCTest
@testable import WordPress

class GutenbergVideoPressUploadProcessorTests: XCTestCase {

    let blockWithDefaultAttrsContent = """
    <!-- wp:videopress/video {"id":-181231834} -->
    <figure class="wp-block-videopress-video wp-block-jetpack-videopress jetpack-videopress-player"></figure>
    <!-- /wp:videopress/video -->
    """

    let blockWithDefaultAttrsResultContent = """
    <!-- wp:videopress/video {"guid":"AbCdE","id":100} -->
    <figure class="wp-block-videopress-video wp-block-jetpack-videopress jetpack-videopress-player"><div class="jetpack-videopress-player__wrapper">
    https://videopress.com/v/AbCdE?resizeToParent=true&amp;cover=true&amp;preloadContent=metadata&amp;useAverageColor=true
    </div></figure>
    <!-- /wp:videopress/video -->
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
    <!-- wp:videopress/video {"autoplay":true,"controls":false,"description":"","id":-181231834,"loop":true,"muted":true,"playsinline":true,"poster":"https://test.files.wordpress.com/2022/02/265-5000x5000-1.jpeg","preload":"none","seekbarColor":"#abb8c3","seekbarLoadingColor":"#cf2e2e","seekbarPlayedColor":"#9b51e0","title":"Demo title","useAverageColor":false} -->
    <figure class="wp-block-videopress-video wp-block-jetpack-videopress jetpack-videopress-player"></figure>
    <!-- /wp:videopress/video -->
    """

    let blockWithAttrsResultContent = """
    <!-- wp:videopress/video {"autoplay":true,"controls":false,"description":"","guid":"AbCdE","id":100,"loop":true,"muted":true,"playsinline":true,"poster":"https:\\/\\/test.files.wordpress.com\\/2022\\/02\\/265-5000x5000-1.jpeg","preload":"none","seekbarColor":"#abb8c3","seekbarLoadingColor":"#cf2e2e","seekbarPlayedColor":"#9b51e0","title":"Demo title","useAverageColor":false} -->
    <figure class="wp-block-videopress-video wp-block-jetpack-videopress jetpack-videopress-player"><div class="jetpack-videopress-player__wrapper">
    https://videopress.com/v/AbCdE?resizeToParent=true&amp;cover=true&amp;autoPlay=true&amp;controls=false&amp;loop=true&amp;muted=true&amp;persistVolume=false&amp;playsinline=true&amp;posterUrl=https%3A%2F%2Ftest.files.wordpress.com%2F2022%2F02%2F265-5000x5000-1.jpeg&amp;preloadContent=none&amp;sbc=%23abb8c3&amp;sbpc=%239b51e0&amp;sblc=%23cf2e2e
    </div></figure>
    <!-- /wp:videopress/video -->
    """

    func testVideoPressBlockWithAttrsProcessor() {
        let gutenbergMediaUploadID = Int32(-181231834)
        let mediaID = 100
        let videoPressGUID = "AbCdE"

        let gutenbergVideoPressUploadProcessor = GutenbergVideoPressUploadProcessor(mediaUploadID: gutenbergMediaUploadID, serverMediaID: mediaID, videoPressGUID: videoPressGUID)
        let resultContent = gutenbergVideoPressUploadProcessor.process(blockWithAttrsContent)

        XCTAssertEqual(resultContent, blockWithAttrsResultContent, "Post content should be updated correctly")
    }
}
