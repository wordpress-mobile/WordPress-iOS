import Testing
import UIKit
import WordPressUI

@MainActor
struct UIImageAssetsTests {

    @Test(arguments: [1.0, 2.0, 3.0])
    func backgroundImageIsRenderedAtTheDisplayScale(displayScale: CGFloat) {
        let traitCollection = UITraitCollection(displayScale: displayScale)

        let image = UIImage.renderBackgroundImage(fill: .clear, border: .blue, traitCollection: traitCollection)

        #expect(image.scale == displayScale)
    }
}
