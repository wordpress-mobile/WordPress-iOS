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

    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.register(LayoutPickerCollectionViewCell.nib, forCellWithReuseIdentifier: layoutCellReuseIdentifier)
        categoryTitle.font = WPStyleGuide.serifFontForTextStyle(UIFont.TextStyle.largeTitle, fontWeight: .semibold).withSize(17)
    }
}

extension LayoutPickerCategoryTableViewCell: UICollectionViewDelegate {

}

extension LayoutPickerCategoryTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }

    func collectionView(_ LayoutPickerCategoryTableViewCell: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: layoutCellReuseIdentifier, for: indexPath) as! LayoutPickerCollectionViewCell
        return cell
    }
}
