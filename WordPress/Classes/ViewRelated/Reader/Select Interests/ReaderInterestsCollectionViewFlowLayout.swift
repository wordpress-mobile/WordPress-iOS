import UIKit

class ReaderInterestsCollectionViewFlowLayout: UICollectionViewFlowLayout {
    @IBInspectable public var itemSpacing: CGFloat = 6
    @IBInspectable public var cellHeight: CGFloat = 40

    private var layoutAttributes: [UICollectionViewLayoutAttributes] = []

    private var isRightToLeft: Bool {
        let layoutDirection: UIUserInterfaceLayoutDirection  = collectionView?.effectiveUserInterfaceLayoutDirection ?? .leftToRight
        return layoutDirection == .rightToLeft
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
                let minX: CGFloat = isRightToLeft ? maxContentWidth - frame.width : 0
                frame.origin = CGPoint(x: minX, y: contentInsets.top)
            } else {
                frame.origin.x = isRightToLeft ? previousFrame.minX - itemSpacing - frame.width : previousFrame.maxX + itemSpacing

                // If the new X position will go off screen move it to the next row
                let needsNewRow = isRightToLeft ? frame.origin.x < 0 : frame.maxX > maxContentWidth
                if needsNewRow {
                    frame.origin.x = isRightToLeft ? (maxContentWidth - frame.width) : 0
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
        contentSize.height = (currentRow + 1) * (cellHeight + itemSpacing) + contentInsets.top + contentInsets.bottom
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
            let size = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath)
        else {
            return CGSize(width: itemSize.width, height: cellHeight)
        }

        return CGSize(width: size.width, height: cellHeight)
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if collectionView?.traitCollection.horizontalSizeClass == .regular {
            return centeredLayoutAttributesForElements(in: rect)
        }

        return self.layoutAttributes.filter {
            return $0.frame.intersects(rect)
        }
    }

    private func centeredLayoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var rows = [Row]()
        var rowY: CGFloat = .greatestFiniteMagnitude

        // Create an array of "rows" based on the y positions
        for attribute in layoutAttributes {
            if attribute.frame.intersects(rect) == false {
                continue
            }

            let minY = attribute.frame.minY

            if rowY != minY {
                rowY = minY

                rows.append(Row(itemSpacing: itemSpacing, isRightToLeft: isRightToLeft))
            }

            rows.last?.add(attribute: attribute)
        }

        return rows.flatMap { (row: Row) -> [UICollectionViewLayoutAttributes] in
            return row.centeredLayoutAttributesIn(width: maxContentWidth)
        }
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributes[indexPath.row]
    }
}

// MARK: - Row Centering Helper Class
private class Row {
    var layoutAttributes = [UICollectionViewLayoutAttributes]()
    let itemSpacing: CGFloat
    let isRightToLeft: Bool

    init(itemSpacing: CGFloat, isRightToLeft: Bool) {
        self.itemSpacing = itemSpacing
        self.isRightToLeft = isRightToLeft
    }

    /// Add a new attribute to the row
    /// - Parameter attribute: layout attribute to be added
    public func add(attribute: UICollectionViewLayoutAttributes) {
        layoutAttributes.append(attribute)
    }

    /// Calculates a new X position for each item in this row based on a new x offset
    /// - Parameter width: The total width of the container view to center in
    /// - Returns: The new centered layout attributes
    public func centeredLayoutAttributesIn(width: CGFloat) -> [UICollectionViewLayoutAttributes] {
        let centerX = (width - rowWidth) * 0.5

        var offset = isRightToLeft ? width - centerX : centerX

        layoutAttributes.forEach { attribute in
            let itemWidth = attribute.frame.width + itemSpacing

            if isRightToLeft {
                attribute.frame.origin.x = offset - attribute.frame.width
                offset -= itemWidth
            } else {
                attribute.frame.origin.x = offset
                offset += itemWidth
            }
        }

        return layoutAttributes
    }

    /// Calculate the total row width including spacing
    private var rowWidth: CGFloat {
        let width = layoutAttributes.reduce(0, { width, attribute -> CGFloat in
            return width + attribute.frame.width
        })

        return width + itemSpacing * CGFloat(layoutAttributes.count - 1)
    }
}
