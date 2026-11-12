import UIKit
import Testing
@testable import AsyncImageKit

@MainActor
@Suite struct ImageViewExtensionsTests {
    @Test func imageViewIsReleasedAfterSetImage() {
        let url = Self.uniqueURL()
        ImageDownloader.shared.setCachedImage(Self.makeImage(), for: url) // A memory-cache hit, so no download
        defer { ImageDownloader.shared.setCachedImage(nil, for: url) }

        weak var weakImageView: UIImageView?
        autoreleasepool {
            let imageView = UIImageView()
            imageView.wp.setImage(with: url)
            #expect(imageView.image != nil)
            weakImageView = imageView
        }

        #expect(weakImageView == nil)
    }

    @Test func imageViewIsReleasedAfterPrepareForReuse() {
        weak var weakImageView: UIImageView?
        autoreleasepool {
            let imageView = UIImageView()
            imageView.wp.prepareForReuse()
            weakImageView = imageView
        }

        #expect(weakImageView == nil)
    }

    // MARK: - Helpers

    static func uniqueURL(_ ext: String = "png") -> URL {
        URL(string: "https://example.files.wordpress.com/tests/\(UUID().uuidString).\(ext)")!
    }

    static func makeImage(color: UIColor = .red) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
            .image { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
            }
    }
}
