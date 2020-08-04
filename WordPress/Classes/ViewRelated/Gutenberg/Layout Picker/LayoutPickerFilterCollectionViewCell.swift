import UIKit

class LayoutPickerFilterCollectionViewCell: UICollectionViewCell {

    static var cellReuseIdentifier: String {
         return "LayoutPickerFilterCollectionViewCell"
     }

    static var nib: UINib {
        return UINib(nibName: "LayoutPickerFilterCollectionViewCell", bundle: Bundle.main)
    }

    static var font: UIFont {
        return WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
    }

    @IBOutlet weak var filterLabel: UILabel!

    var filter: GutenbergLayoutSection? = nil {
        didSet {
            filterLabel.text = filter?.filterTitle
            filterLabel.accessibilityLabel = filter?.section.title
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        filterLabel.font = LayoutPickerFilterCollectionViewCell.font
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        filter = nil
    }
}
