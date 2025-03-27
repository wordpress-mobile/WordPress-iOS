import UIKit

/// A flow layout that properly invalidates the layout when the collection view's bounds changed,
/// (e.g., orientation changes).
///
/// This method ensures that we work with the latest/correct bounds after the size change, and potentially
/// avoids race conditions where we might get incorrect bounds while the view is still in transition.
///
/// See: https://developer.apple.com/documentation/uikit/uicollectionviewlayout/1617781-shouldinvalidatelayout
class AdaptiveCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // NOTE: Apparently we need to *manually* invalidate the layout because `invalidateLayout()`
        // is NOT called after this method returns true.
        if let collectionView, collectionView.bounds.size != newBounds.size {
            invalidateLayout()
        }
        return super.shouldInvalidateLayout(forBoundsChange: newBounds)
    }
}
