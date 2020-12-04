import UIKit

class LayoutPickerFilterCollectionViewCell: UICollectionViewCell {

    static var cellReuseIdentifier: String {
         return "LayoutPickerCategoryCollectionViewCell"
     }

    static var nib: UINib {
        return UINib(nibName: "LayoutPickerCategoryCollectionViewCell", bundle: Bundle.main)
    }

    @IBOutlet weak var filterLabel: UILabel!

    var displayCategory: GutenbergLayoutDisplayCategory? = nil
}
