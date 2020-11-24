import UIKit

protocol CollapsableHeaderFilterBarDelegate: class {
    func numberOfFilters() -> Int
    func filter(forIndex: Int) -> CollabsableHeaderFilterOption
    func didSelectFilter(withIndex selectedIndex: IndexPath, withSelectedIndexes selectedIndexes: [IndexPath])
    func didDeselectFilter(withIndex index: IndexPath, withSelectedIndexes selectedIndexes: [IndexPath])
}

class CollapsableHeaderFilterBar: UICollectionView {
    var filterDelegate: CollapsableHeaderFilterBarDelegate?
    private let defaultCellHeight: CGFloat = 44
    private let defaultCellWidth: CGFloat = 105

    var shouldShowGhostContent: Bool = false {
        didSet {
            reloadData()
        }
    }

    init() {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        collectionViewLayout.minimumInteritemSpacing = 12
        collectionViewLayout.minimumLineSpacing = 10
        collectionViewLayout.scrollDirection = .horizontal
        super.init(frame: .zero, collectionViewLayout: collectionViewLayout)
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        register(CollabsableHeaderFilterCollectionViewCell.nib, forCellWithReuseIdentifier: CollabsableHeaderFilterCollectionViewCell.cellReuseIdentifier)
        self.delegate = self
        self.dataSource = self
        self.backgroundColor = .clear
        self.isOpaque = false
    }

    private func deselectItem(_ indexPath: IndexPath) {
        deselectItem(at: indexPath, animated: true)
        collectionView(self, didDeselectItemAt: indexPath)
    }
}

extension CollapsableHeaderFilterBar: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if collectionView.cellForItem(at: indexPath)?.isSelected ?? false {
            deselectItem(indexPath)
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems else { return }
        filterDelegate?.didSelectFilter(withIndex: indexPath, withSelectedIndexes: indexPathsForSelectedItems)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        filterDelegate?.didDeselectFilter(withIndex: indexPath, withSelectedIndexes: collectionView.indexPathsForSelectedItems ?? [])
    }
}

extension CollapsableHeaderFilterBar: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard !shouldShowGhostContent, let filter = filterDelegate?.filter(forIndex: indexPath.item) else {
            return CGSize(width: defaultCellWidth, height: defaultCellHeight)
        }

        let width = CollabsableHeaderFilterCollectionViewCell.estimatedWidth(forFilter: filter)
        return CGSize(width: width, height: defaultCellHeight)
     }
}

extension CollapsableHeaderFilterBar: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shouldShowGhostContent ? 1 : (filterDelegate?.numberOfFilters() ?? 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellReuseIdentifier = CollabsableHeaderFilterCollectionViewCell.cellReuseIdentifier
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? CollabsableHeaderFilterCollectionViewCell else {
            fatalError("Expected the cell with identifier \"\(cellReuseIdentifier)\" to be a \(CollabsableHeaderFilterCollectionViewCell.self). Please make sure the collection view is registering the correct nib before loading the data")
        }

        if shouldShowGhostContent {
            cell.ghostAnimationWillStart()
            cell.startGhostAnimation(style: GhostCellStyle.muriel)
        } else {
            cell.stopGhostAnimation()
            cell.filter = filterDelegate?.filter(forIndex: indexPath.item)
        }

        return cell
    }
}
