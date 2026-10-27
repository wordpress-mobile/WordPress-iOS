import CoreGraphics
import Testing
@testable import WordPressKit

struct SiteDesignRequestTests {
    @Test func sendsThePreviewSizeAndScale() {
        let request = SiteDesignRequest(withThumbnailSize: CGSize(width: 350, height: 450), scale: 3)

        #expect(request.parameters["preview_width"] as? String == "350.0")
        #expect(request.parameters["preview_height"] as? String == "450.0")
        #expect(request.parameters["scale"] as? CGFloat == 3)
    }
}
