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

    static func title(forFilter filter: GutenbergLayoutSection?, isSelected: Bool = false) -> String {
        let section = filter?.section
        let emoji = isSelected ? nil : section?.emoji
        return [emoji, section?.title].compactMap { $0 }.joined(separator: " ")
    }

    static func estimatedWidth(forFilter filter: GutenbergLayoutSection) -> CGFloat {
        let size = title(forFilter: filter).size(withAttributes: [
            NSAttributedString.Key.font: font
        ])

        return size.width + 32
    }

    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var pillBackgroundView: UIView!
    @IBOutlet weak var checkmark: UIImageView!

    var filter: GutenbergLayoutSection? = nil {
        didSet {
            let section = filter?.section
            filterLabel.text = LayoutPickerFilterCollectionViewCell.title(forFilter: filter)
            filterLabel.accessibilityLabel = section?.title
        }
    }

    var checkmarkTintColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor.darkText
                } else {
                    return UIColor.white
                }
            }
        } else {
            return UIColor.white
        }
    }

    override var isSelected: Bool {
        didSet {
            updateSelectedStyle()
            checkmark.isHidden = !isSelected
            filterLabel.text = LayoutPickerFilterCollectionViewCell.title(forFilter: filter, isSelected: isSelected)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        filterLabel.font = LayoutPickerFilterCollectionViewCell.font
        checkmark.image = UIImage.gridicon(.checkmark)
        checkmark.tintColor = checkmarkTintColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        filter = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateSelectedStyle()
            }
        }
    }

    private func updateSelectedStyle() {
        if #available(iOS 13.0, *) {
            let oppositeInterfaceStyle: UIUserInterfaceStyle = (traitCollection.userInterfaceStyle == .dark) ? .light : .dark
            let selectedColor: UIColor = UIColor.systemGray6.color(for: UITraitCollection(userInterfaceStyle: oppositeInterfaceStyle))
            pillBackgroundView.backgroundColor = isSelected ? selectedColor : .quaternarySystemFill
        } else {
            pillBackgroundView.backgroundColor = isSelected ? .gray(.shade5) : .neutral(.shade5)
        }

        if #available(iOS 13.0, *), traitCollection.userInterfaceStyle == .dark {
            filterLabel.textColor = isSelected ? .darkText : .white
        } else {
            filterLabel.textColor = isSelected ? .white : .darkText
        }
    }
}
