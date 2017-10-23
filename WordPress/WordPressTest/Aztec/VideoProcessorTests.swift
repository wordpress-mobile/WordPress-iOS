import XCTest
@testable import WordPress

class VideoProcessorTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testVideoPressPreProcessor() {
        let shortcodeProcessor = VideoShortcodeProcessor.videoPressPreProcessor
        let sampleText = "Before Text[wpvideo OcobLTqC w=640 h=400 autoplay=true html5only=true] After Text"
        let parsedText = shortcodeProcessor.process(sampleText)
        XCTAssertEqual(parsedText, "Before Text<video src=\"videopress://OcobLTqC\" data-wpvideopress=\"OcobLTqC\" poster=\"videopress://OcobLTqC\" width=640 height=400 /> After Text")
    }

    func testWordPressPreProcessor() {
        let shortcodeProcessor = VideoShortcodeProcessor.wordPressVideoPreProcessor
        let sampleText = "[video src=\"video-source.mp4\"]"
        let parsedText = shortcodeProcessor.process(sampleText)
        XCTAssertEqual(parsedText, "<video src=\"video-source.mp4\" />")
    }

    func testVideoPressPostProcessor() {
        let shortcodeProcessor = VideoShortcodeProcessor.videoPressPostProcessor
        let sampleText = "Before Text<video src=\"videopress://OcobLTqC\" data-wpvideopress=\"OcobLTqC\" width=640 height=400 /> After Text<video src=\"video-source.mp4\" />"
        let parsedText = shortcodeProcessor.process(sampleText)
        XCTAssertEqual(parsedText, "Before Text[wpvideo OcobLTqC w=640 h=400 ] After Text<video src=\"video-source.mp4\" />")
    }

    func testWordPressPostProcessor() {
        let shortcodeProcessor = VideoShortcodeProcessor.wordPressVideoPostProcessor
        let sampleText = "<video src=\"video-source.mp4\" />"
        let parsedText = shortcodeProcessor.process(sampleText)
        XCTAssertEqual(parsedText, "[video src=\"video-source.mp4\" ]")
    }

}
