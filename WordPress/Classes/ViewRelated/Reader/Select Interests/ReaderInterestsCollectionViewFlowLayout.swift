import UIKit

protocol ReaderInterestsCollectionViewFlowLayoutDelegate: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout: ReaderInterestsCollectionViewFlowLayout, sizeForOverflowItem at: IndexPath, remainingItems: Int?) -> CGSize
}

class ReaderInterestsCollectionViewFlowLayout: UICollectionViewFlowLayout {
    weak var delegate: ReaderInterestsCollectionViewFlowLayoutDelegate?

    @IBInspectable var itemSpacing: CGFloat = 6
    @IBInspectable var cellHeight: CGFloat = 40
    @IBInspectable var allowsCentering: Bool = true

    /// Whether or not the layout should be force centered
    @IBInspectable var isCentered: Bool = false

    // Collapsing/Expanding support
    static let overflowItemKind = "InterestsOverflowItem"
    var maxNumberOfDisplayedLines: Int?
    var isExpanded: Bool = false
    var remainingItems: Int?

    private var layoutAttributes: [UICollectionViewLayoutAttributes] = []

    private var isRightToLeft: Bool {
        let layoutDirection: UIUserInterfaceLayoutDirection = collectionView?.effectiveUserInterfaceLayoutDirection ?? .leftToRight
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

    func collectionView(_ collectionView: UICollectionView, layout: ReaderInterestsCollectionViewFlowLayout, sizeForOverflowItem at: IndexPath) -> CGSize {
        return .zero
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

        // If we're expanded we will show the 'hide' option at the end
        let count = isExpanded ? numberOfItems + 1 : numberOfItems

        for item in 0 ..< count {
            let indexPath: IndexPath = IndexPath(row: item, section: 0)
            let isCollapseItem = item == numberOfItems
            let itemSize = isCollapseItem ? sizeForOverflowItem(at: indexPath) : sizeForItem(at: indexPath)
            var frame: CGRect = CGRect(origin: .zero, size: itemSize)

            if item == 0 {
                let minX: CGFloat = isRightToLeft ? maxContentWidth - frame.width : 0
                frame.origin = CGPoint(x: minX, y: contentInsets.top)
            } else {
                frame.origin.x = isRightToLeft ? previousFrame.minX - itemSpacing - frame.width : previousFrame.maxX + itemSpacing

                // If the new X position will go off screen move it to the next row
                let needsNewRow = isRightToLeft ? frame.origin.x < 0 : frame.maxX > maxContentWidth
                if needsNewRow {
                    // Cap the display to the maximum number of lines, and display the grouped item
                    // If we're in the expanded state display all the items
                    if let maxLines = maxNumberOfDisplayedLines, isExpanded == false, Int(currentRow) >= maxLines - 1 {
                        remainingItems = numberOfItems - item + 1

                        // Remove the last added item and replace it with the expand item
                        // If there's only 1 token left, don't remove it
                        if layoutAttributes.count > 1 {
                            layoutAttributes.removeLast()
                        }

                        // Get the frame for the item that appears before the item we just removed
                        let lastFrame = layoutAttributes.last?.frame ?? previousFrame
                        var overflowFrame = previousFrame

                        overflowFrame.size = sizeForOverflowItem(at: indexPath, remainingItems: remainingItems)
                        overflowFrame.origin.x = isRightToLeft ? lastFrame.minX - itemSpacing - overflowFrame.width : lastFrame.maxX + itemSpacing

                        let overflowAttribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: Self.overflowItemKind,
                                                                                 with: indexPath)
                        overflowAttribute.frame = overflowFrame

                        layoutAttributes.append(overflowAttribute)

                        break
                    }

                    frame.origin.x = isRightToLeft ? (maxContentWidth - frame.width) : 0
                    currentRow += 1
                }

                frame.origin.y = currentRow * (cellHeight + itemSpacing) + contentInsets.top
                remainingItems = nil
            }

            let attribute: UICollectionViewLayoutAttributes

            if isCollapseItem {
                attribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: Self.overflowItemKind, with: indexPath)
            } else {
                attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            }

            attribute.frame = frame
            layoutAttributes.append(attribute)

            previousFrame = frame
        }

        // Update content size
        contentSize.width = maxContentWidth
        contentSize.height = (currentRow + 1) * cellHeight + contentInsets.top + contentInsets.bottom + (currentRow * itemSpacing)
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

    private func sizeForOverflowItem(at indexPath: IndexPath, remainingItems: Int? = nil) -> CGSize {
        guard
            let collectionView = collectionView,
            let delegate = delegate
        else {
            return CGSize(width: itemSize.width, height: cellHeight)
        }

        let size = delegate.collectionView(collectionView, layout: self, sizeForOverflowItem: indexPath, remainingItems: remainingItems)
        return CGSize(width: size.width, height: cellHeight)
    }


    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if allowsCentering, isCentered || collectionView?.traitCollection.horizontalSizeClass == .regular {
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
        guard indexPath.row < layoutAttributes.count else {
            return nil
        }
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
