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

    static func title(forFilter filter: GutenbergLayoutSection?) -> String {
        let section = filter?.section
        return [section?.emoji, section?.title].compactMap { $0 }.joined(separator: " ")
    }

    static func estimatedWidth(forFilter filter: GutenbergLayoutSection) -> CGFloat {
        let size = title(forFilter: filter).size(withAttributes: [
            NSAttributedString.Key.font: font
        ])

        return size.width + 32
    }

    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var pillBackgroundView: UIView!

    var filter: GutenbergLayoutSection? = nil {
        didSet {
            let section = filter?.section
            filterLabel.text = LayoutPickerFilterCollectionViewCell.title(forFilter: filter)
            filterLabel.accessibilityLabel = section?.title
        }
    }

    override var isSelected: Bool {
        didSet {
            if #available(iOS 13.0, *) {
                let selectedColor: UIColor = UIColor.systemGray6.color(for: UITraitCollection(userInterfaceStyle: .dark))
                pillBackgroundView.backgroundColor = isSelected ? selectedColor : .quaternarySystemFill
            } else {
                pillBackgroundView.backgroundColor = isSelected ? .gray(.shade5) : .neutral(.shade5)
            }

            filterLabel.textColor = isSelected ? .white : .text
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
