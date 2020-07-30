import UIKit
import Gutenberg

protocol LayoutPickerCategoryTableViewCellDelegate: class {
    func didSelectLayoutAt(_ position: Int, forCell cell: LayoutPickerCategoryTableViewCell)
    func didDeselectItem(forCell cell: LayoutPickerCategoryTableViewCell)
}

class LayoutPickerCategoryTableViewCell: UITableViewCell {

    static var nib: UINib {
        return UINib(nibName: "LayoutPickerCategoryTableViewCell", bundle: Bundle.main)
    }
    let layoutCellReuseIdentifier = "LayoutCollectionViewCell"

    @IBOutlet weak var categoryTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    weak var delegate: LayoutPickerCategoryTableViewCellDelegate?

    private var layouts = [GutenbergLayout]() {
        didSet {
            collectionView.reloadData()
        }
    }
    var displayCategory: GutenbergLayoutDisplayCategory? = nil {
        didSet {
            layouts = displayCategory?.layouts ?? []
            categoryTitle.text = displayCategory?.category.description ?? ""
            collectionView.contentOffset = displayCategory?.scrollOffset ?? .zero
        }
    }

    override func prepareForReuse() {
        displayCategory?.scrollOffset = collectionView.contentOffset
        delegate = nil
        super.prepareForReuse()
        collectionView.contentOffset.x = 0
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(LayoutPickerCollectionViewCell.nib, forCellWithReuseIdentifier: layoutCellReuseIdentifier)
        categoryTitle.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.headline, fontWeight: .semibold)
    }

    private func deselectItem(_ indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView(collectionView, didDeselectItemAt: indexPath)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if !selected, let selectedItems = collectionView.indexPathsForSelectedItems {
            selectedItems.forEach { (indexPath) in
                deselectItem(indexPath)
            }
        }

        super.setSelected(selected, animated: animated)
    }

    func selectItemAt(_ position: Int) {
        collectionView.selectItem(at: IndexPath(item: position, section: 0), animated: false, scrollPosition: [])
    }
}

extension LayoutPickerCategoryTableViewCell: UICollectionViewDelegate {
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

extension LayoutPickerCategoryTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 148.0, height: 230.0)
     }
}

extension LayoutPickerCategoryTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 30 // Static layouts currently only have one layout per category. Adding multiple in here to help test
    }

    func collectionView(_ LayoutPickerCategoryTableViewCell: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: layoutCellReuseIdentifier, for: indexPath) as! LayoutPickerCollectionViewCell
        cell.layout = layouts[0] // Static layouts currently only have one layout per category. Reusing the first to help test
        return cell
    }
}
