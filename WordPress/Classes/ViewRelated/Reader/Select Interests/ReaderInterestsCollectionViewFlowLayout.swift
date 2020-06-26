import UIKit

class ReaderInterestsCollectionViewFlowLayout: UICollectionViewFlowLayout {
    @IBInspectable public var itemSpacing: CGFloat = 6
    @IBInspectable public var cellHeight: CGFloat = 40

    private var layoutAttributes: [UICollectionViewLayoutAttributes] = []
    private var layoutDirection: UIUserInterfaceLayoutDirection {
        return collectionView?.effectiveUserInterfaceLayoutDirection ?? .leftToRight
    }

    // The content width minus the content insets used when calculating rows, and centering
    private var maxContentWidth: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }

        let contentInsets: UIEdgeInsets = collectionView.contentInset

        return collectionView.bounds.width - (contentInsets.left + contentInsets.right)
    }

    /// The calculated content size for the view
    private var contentSize: CGSize = .zero

    override open var collectionViewContentSize: CGSize {
        return contentSize
    }

    override func prepare() {
        guard let collectionView = collectionView else {
            return
        }

        let contentInsets = collectionView.contentInset
        let isRTL = layoutDirection == .rightToLeft

        // The current row used to calculate the y position and the total content height
        var currentRow: CGFloat = 0

        // Keeps track of the previous items frame so we can properly calculate the current item's x position
        var previousFrame: CGRect = .zero

        let numberOfItems: Int = collectionView.numberOfItems(inSection: 0)

        for item in 0 ..< numberOfItems {
            let indexPath: IndexPath = IndexPath(row: item, section: 0)

            let itemSize = sizeForItem(at: indexPath)
            var frame: CGRect = CGRect(origin: .zero, size: itemSize)

            if item == 0 {
                let minX: CGFloat = isRTL ? maxContentWidth - frame.width : 0
                frame.origin = CGPoint(x: minX, y: contentInsets.top)
            } else {
                if isRTL {
                    frame.origin.x = previousFrame.minX - itemSpacing - frame.width
                } else {
                    frame.origin.x = previousFrame.maxX + itemSpacing
                }

                // If the new X position will go off screen move it to the next row
                let needsNewRow = isRTL ? frame.origin.x < 0 : frame.maxX > maxContentWidth
                if needsNewRow {
                    frame.origin.x = isRTL ? (maxContentWidth - frame.width) : 0
                    currentRow += 1
                }

                frame.origin.y = currentRow * (cellHeight + itemSpacing) + contentInsets.top
            }

            let attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attribute.frame = frame

            layoutAttributes.append(attribute)

            previousFrame = frame
        }

        // Update content size
        contentSize.width = maxContentWidth
        contentSize.height = currentRow * (cellHeight + itemSpacing) + contentInsets.top + contentInsets.bottom
    }

    override func invalidateLayout() {
        contentSize = .zero
        layoutAttributes = []

        super.invalidateLayout()
    }

    /// Get the size for the given index path from the delegate, or the default item size
    /// - Parameter indexPath: index path for the item
    /// - Returns: The width for the cell either from the delegate or the itemSize property
    private func sizeForItem(at indexPath: IndexPath) -> CGSize {
        guard
            let collectionView = collectionView,
            let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout,
            delegate.responds(to: #selector(delegate.collectionView(_:layout:sizeForItemAt:)))
            else {
                return CGSize(width: itemSize.width, height: cellHeight)
        }

        let size = delegate.collectionView!(collectionView, layout: self, sizeForItemAt: indexPath)
        return CGSize(width: size.width, height: cellHeight)
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()

        for attribute in self.layoutAttributes {
            if attribute.frame.intersects(rect) {
                layoutAttributes.append(attribute)
            }
        }

        return layoutAttributes
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributes[indexPath.row]
    }

}
