import UIKit

extension UIImage: AsyncImage {
    public var thumb: UIImage? {
        return self
    }

    public func thumbnail(finishedRetrievingThumbnail: @escaping (UIImage?) -> ()) {}

    public func full(finishedRetrievingFullImage: @escaping (UIImage?) -> ()) {}

    public func cancel() {}
}
