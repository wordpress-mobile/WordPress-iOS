import Foundation
import Testing
import WordPressUI

struct SiteIconViewModelTests {
    private let url = URL(string: "https://example.com/icon.png")!

    @Test(arguments: [1.0, 2.0, 3.0])
    func imageURLIsSizedForTheDisplayScale(displayScale: CGFloat) {
        var viewModel = SiteIconViewModel(imageURL: url)
        viewModel.sizeImageURL = { url, displayScale in
            URL(string: "\(url.absoluteString)?s=\(Int(40 * displayScale))")
        }

        #expect(
            viewModel.imageURL(forDisplayScale: displayScale)
                == URL(string: "https://example.com/icon.png?s=\(Int(40 * displayScale))")
        )
    }

    @Test
    func imageURLIsUnchangedWithoutSizing() {
        let viewModel = SiteIconViewModel(imageURL: url)

        #expect(viewModel.imageURL(forDisplayScale: 3) == url)
    }

    @Test
    func noImageURLIsNotSized() {
        var viewModel = SiteIconViewModel()
        viewModel.sizeImageURL = { url, _ in url }

        #expect(viewModel.imageURL(forDisplayScale: 3) == nil)
    }
}
