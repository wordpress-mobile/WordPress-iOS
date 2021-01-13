import UIKit
import Gutenberg

protocol LayoutPickerSectionTableViewCellDelegate: class {
    func didSelectLayoutAt(_ position: Int, forCell cell: LayoutPickerSectionTableViewCell)
    func didDeselectItem(forCell cell: LayoutPickerSectionTableViewCell)
    func accessibilityElementDidBecomeFocused(forCell cell: LayoutPickerSectionTableViewCell)
}

class LayoutPickerSectionTableViewCell: UITableViewCell {

    static let cellReuseIdentifier = "LayoutPickerSectionTableViewCell"
    static let nib = UINib(nibName: "LayoutPickerSectionTableViewCell", bundle: Bundle.main)
    static let expectedTumbnailSize = CGSize(width: 160.0, height: 230.0)
    static let estimatedCellHeight: CGFloat = 310.0

    @IBOutlet weak var categoryTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    weak var delegate: LayoutPickerSectionTableViewCellDelegate?

    private var layouts = [PageTemplateLayout]() {
        didSet {
            collectionView.reloadData()
        }
    }
    var section: GutenbergLayoutSection? = nil {
        didSet {
            layouts = section?.layouts ?? []
            categoryTitle.text = section?.section.desc ?? ""
            collectionView.contentOffset = section?.scrollOffset ?? .zero
        }
    }

    var isGhostCell: Bool = false

    override func prepareForReuse() {
        section?.scrollOffset = collectionView.contentOffset
        delegate = nil
        super.prepareForReuse()
        collectionView.contentOffset.x = 0
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(CollapsableHeaderCollectionViewCell.nib, forCellWithReuseIdentifier: CollapsableHeaderCollectionViewCell.cellReuseIdentifier)
        categoryTitle.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.headline, fontWeight: .semibold)
        categoryTitle.layer.masksToBounds = true
        categoryTitle.layer.cornerRadius = 4
    }

    private func deselectItem(_ indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView(collectionView, didDeselectItemAt: indexPath)
    }

    func deselectItems() {
        guard let selectedItems = collectionView.indexPathsForSelectedItems else { return }
        selectedItems.forEach { (indexPath) in
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }

    func selectItemAt(_ position: Int) {
        collectionView.selectItem(at: IndexPath(item: position, section: 0), animated: false, scrollPosition: [])
    }
}

extension LayoutPickerSectionTableViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if collectionView.cellForItem(at: indexPath)?.isSelected ?? false {
            deselectItem(indexPath)
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectLayoutAt(indexPath.item, forCell: self)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        delegate?.didDeselectItem(forCell: self)
    }
}

extension LayoutPickerSectionTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return LayoutPickerSectionTableViewCell.expectedTumbnailSize
     }
}

extension LayoutPickerSectionTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isGhostCell ? 1 : layouts.count
    }

    func collectionView(_ LayoutPickerCategoryTableViewCell: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellReuseIdentifier = CollapsableHeaderCollectionViewCell.cellReuseIdentifier
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? CollapsableHeaderCollectionViewCell else {
            fatalError("Expected the cell with identifier \"\(cellReuseIdentifier)\" to be a \(CollapsableHeaderCollectionViewCell.self). Please make sure the collection view is registering the correct nib before loading the data")
        }
        guard !isGhostCell else {
            cell.startGhostAnimation(style: GhostCellStyle.muriel)
            return cell
        }

        let layout = layouts[indexPath.row]
        cell.previewURL = layout.preview
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = layout.slug
        return cell
    }
}

/// Accessibility
extension LayoutPickerSectionTableViewCell {
    override func accessibilityElementDidBecomeFocused() {
        delegate?.accessibilityElementDidBecomeFocused(forCell: self)
    }
}

class AccessibleCollectionView: UICollectionView {
    override func accessibilityElementCount() -> Int {
        guard let dataSource = dataSource else {
            return 0
        }

        return dataSource.collectionView(self, numberOfItemsInSection: 0)
    }
}
