import UIKit

class LayoutPickerFilterCollectionViewCell: UICollectionViewCell {

    static var cellReuseIdentifier: String {
         return "LayoutPickerFilterCollectionViewCell"
     }

    static var nib: UINib {
        return UINib(nibName: "LayoutPickerFilterCollectionViewCell", bundle: Bundle.main)
    }

    @IBOutlet weak var filterLabel: UILabel!

    var filter: GutenbergLayoutSection? = nil
}
