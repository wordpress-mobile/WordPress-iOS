import UIKit

protocol FilterBarDelegate {
    func numberOfFilters() -> Int
    func filter(forIndex: Int) -> GutenbergLayoutSection
    func didSelectFilter(withIndex selectedIndex: IndexPath, withSelectedIndexes selectedIndexes: [IndexPath])
    func didDeselectFilter(withIndex index: IndexPath, withSelectedIndexes selectedIndexes: [IndexPath])
}

class GutenbergLayoutFilterBar: UICollectionView {
    var filterDelegate: FilterBarDelegate?
    private let defaultCellHeight: CGFloat = 44
    private let defaultCellWidth: CGFloat = 105
    var shouldShowGhostContent: Bool = false {
        didSet {
            reloadData()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        register(LayoutPickerFilterCollectionViewCell.nib, forCellWithReuseIdentifier: LayoutPickerFilterCollectionViewCell.cellReuseIdentifier)
        self.delegate = self
        self.dataSource = self
    }

    private func deselectItem(_ indexPath: IndexPath) {
        deselectItem(at: indexPath, animated: true)
        collectionView(self, didDeselectItemAt: indexPath)
    }
}

extension GutenbergLayoutFilterBar: UICollectionViewDelegate {
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

extension GutenbergLayoutFilterBar: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard !shouldShowGhostContent, let filter = filterDelegate?.filter(forIndex: indexPath.item) else {
            return CGSize(width: defaultCellWidth, height: defaultCellHeight)
        }

        let width = LayoutPickerFilterCollectionViewCell.estimatedWidth(forFilter: filter)
        return CGSize(width: width, height: defaultCellHeight)
     }
}

extension GutenbergLayoutFilterBar: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shouldShowGhostContent ? 1 : (filterDelegate?.numberOfFilters() ?? 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LayoutPickerFilterCollectionViewCell.cellReuseIdentifier, for: indexPath) as! LayoutPickerFilterCollectionViewCell

        if shouldShowGhostContent {
            cell.ghostAnimationWillStart()
            cell.startGhostAnimation()
        } else {
            cell.stopGhostAnimation()
            cell.filter = filterDelegate?.filter(forIndex: indexPath.item)
        }

        return cell
    }
}
