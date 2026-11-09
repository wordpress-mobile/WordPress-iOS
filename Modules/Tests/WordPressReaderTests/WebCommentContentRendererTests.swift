import Testing
import UIKit
@testable import WordPressReader

@MainActor
@Suite("WebCommentContentRenderer")
struct WebCommentContentRendererTests {
    @Test("a new reading theme replaces the styles of a renderer that already rendered")
    func headFollowsDisplaySettings() {
        let soft = ReaderDisplaySettings(color: .soft, font: .sans, size: .normal)

        let renderer = WebCommentContentRenderer()
        let standardHead = renderer.makeHead()

        renderer.displaySettings = soft

        let expected = WebCommentContentRenderer()
        expected.displaySettings = soft
        #expect(renderer.makeHead() == expected.makeHead())
        #expect(renderer.makeHead() != standardHead)
    }
}
