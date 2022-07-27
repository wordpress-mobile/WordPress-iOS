import Foundation

/// `UIImageView`s without height and width constraints are automatically resized to their intrinsic content size when
/// an image is set.  This subclass exists to allow the creation of image views that don't have size constraints and that
/// are NOT resized when their image is set.
///
/// This is useful to let the dimensions of the `UIImageView` be defined by neighbor views.  A good example of this is when you want
/// the image view to have the same height as a neighbor text field.
///
class FixedSizeImageView: UIImageView {
    override var intrinsicContentSize: CGSize {
        return .zero
    }
}
