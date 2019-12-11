import UIKit

protocol AsyncImage {
    var thumb: UIImage? { get }

    func thumbnail(finishedRetrievingThumbnail: @escaping (UIImage?) -> ())

    func full(finishedRetrievingFullImage: @escaping (UIImage?) -> ())

    func cancel()
}
