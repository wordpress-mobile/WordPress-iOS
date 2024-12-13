import UIKit

public final class AnimatedImage: UIImage, @unchecked Sendable {
    public private(set) var gifData: Data?
    public var targetSize: CGSize?

    static let maximumAllowedSize = 30_000_000

    public convenience init?(gifData: Data) {
        self.init(data: gifData, scale: 1)

        guard gifData.count < AnimatedImage.maximumAllowedSize else {
            return // The image is too large to store in memory and play
        }

        self.gifData = gifData
    }
}
