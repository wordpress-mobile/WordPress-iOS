import UIKit

class LayoutPickerFilterCollectionViewCell: UICollectionViewCell {

    static var cellReuseIdentifier: String {
         return "LayoutPickerFilterCollectionViewCell"
     }

    static var nib: UINib {
        return UINib(nibName: "LayoutPickerFilterCollectionViewCell", bundle: Bundle.main)
    }

    @IBOutlet weak var filterLabel: UILabel!

    var filter: GutenbergLayoutSection? = nil {
        didSet {
            filterLabel.text = [filter?.section.emoji, filter?.section.title].compactMap { $0 }.joined(separator: " ")
            filterLabel.accessibilityLabel = filter?.section.title
        }
    }
}
