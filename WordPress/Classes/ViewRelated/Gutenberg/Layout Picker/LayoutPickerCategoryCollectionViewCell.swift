import UIKit

class LayoutPickerCategoryCollectionViewCell: UICollectionViewCell {

    static var cellReuseIdentifier: String {
         return "LayoutPickerCategoryCollectionViewCell"
     }

    static var nib: UINib {
        return UINib(nibName: "LayoutPickerCategoryCollectionViewCell", bundle: Bundle.main)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
