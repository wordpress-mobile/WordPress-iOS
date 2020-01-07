import UIKit

public protocol AsyncImage {
    var thumb: UIImage? { get }

    var isEdited: Bool { get set }

    var editedImage: UIImage? { get set }

    func thumbnail(finishedRetrievingThumbnail: @escaping (UIImage?) -> ())

    func full(finishedRetrievingFullImage: @escaping (UIImage?) -> ())

    func cancel()
}

extension AsyncImage {
    public var isEdited: Bool {
        get {
            return objc_getAssociatedObject(self, &AsyncImageKeys.isEdited) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AsyncImageKeys.isEdited, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    public var editedImage: UIImage? {
        get {
            return objc_getAssociatedObject(self, &AsyncImageKeys.editedImage) as? UIImage ?? nil
        }
        set {
            objc_setAssociatedObject(self, &AsyncImageKeys.editedImage, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

private enum AsyncImageKeys {
    static var isEdited = "isEdited"
    static var editedImage = "editedImage"
}
