import UIKit
import Gutenberg

class LayoutPickerCategoryTableViewCell: UITableViewCell {

    static var nib: UINib {
        return UINib(nibName: "LayoutPickerCategoryTableViewCell", bundle: Bundle.main)
    }
    let layoutCellReuseIdentifier = "LayoutCollectionViewCell"

    @IBOutlet weak var categoryTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    var layouts = [GutenbergLayout]() {
        didSet {
            collectionView.reloadData()
        }
    }
    var category: GutenbergLayoutCategory? = nil {
        didSet {
            categoryTitle.text = category?.description ?? ""
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        collectionView.contentOffset.x = 0
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(LayoutPickerCollectionViewCell.nib, forCellWithReuseIdentifier: layoutCellReuseIdentifier)
        categoryTitle.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold).withSize(17)
    }

    override var isSelected: Bool {
        didSet {
            if !isSelected {
                collectionView.indexPathsForSelectedItems?.forEach({ (indexPath) in
                    self.collectionView.deselectItem(at: indexPath, animated: true)
                })
            }
        }
    }
}

extension LayoutPickerCategoryTableViewCell: UICollectionViewDelegate {

}

extension LayoutPickerCategoryTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 148.0, height: 230.0)
     }
}

extension LayoutPickerCategoryTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return layouts.count
        return 30
    }

    func collectionView(_ LayoutPickerCategoryTableViewCell: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: layoutCellReuseIdentifier, for: indexPath) as! LayoutPickerCollectionViewCell
        cell.layout = layouts.first
        return cell
    }
}
