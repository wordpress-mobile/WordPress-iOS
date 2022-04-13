import Foundation

class DynamicHeightCollectionView: AccessibleCollectionView {
    override func layoutSubviews() {
        super.layoutSubviews()

        if bounds.size != intrinsicContentSize {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        var size = contentSize
        size.width = superview?.bounds.size.width ?? 0
        return size
    }
}
