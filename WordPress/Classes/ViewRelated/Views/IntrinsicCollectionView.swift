import UIKit

/// This UICollectionView subclass allows us to use UIStackView along with Collection Views. Intrinsic Content Size
/// will be automatically calculated, based on the Collection View's Content Size.
///
@objc class IntrinsicCollectionView: UICollectionView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != intrinsicContentSize {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        return collectionViewLayout.collectionViewContentSize
    }
}
