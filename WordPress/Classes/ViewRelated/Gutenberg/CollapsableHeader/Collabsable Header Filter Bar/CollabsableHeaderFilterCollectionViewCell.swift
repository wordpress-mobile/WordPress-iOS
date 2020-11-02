import UIKit

protocol CollabsableHeaderFilterOption: class {
    var title: String { get }
    var emoji: String? { get }
}

class CollabsableHeaderFilterCollectionViewCell: UICollectionViewCell {

    static let cellReuseIdentifier = "\(CollabsableHeaderFilterCollectionViewCell.self)"
    static let nib = UINib(nibName: "\(CollabsableHeaderFilterCollectionViewCell.self)", bundle: Bundle.main)

    static var font: UIFont {
        return WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
    }

    private static let combinedLeftRightMargin: CGFloat = 32
    static func estimatedWidth(forFilter filter: CollabsableHeaderFilterOption) -> CGFloat {
        /// The emoji below is used as a placeholder to estimate the size of the title. We don't use the actual emoji provided by the API because this could be nil
        /// and we want to allow space for a checkmark when the cell is selected.
        let size = "👋 \(filter.title)".size(withAttributes: [
            NSAttributedString.Key.font: font
        ])

        return size.width + combinedLeftRightMargin
    }

    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var pillBackgroundView: UIView!
    @IBOutlet weak var checkmark: UIImageView!

    var filter: CollabsableHeaderFilterOption? = nil {
        didSet {
            filterLabel.text = filterTitle
            filterLabel.accessibilityLabel = filter?.title
        }
    }

    var filterTitle: String {
        let emoji = isSelected ? nil : filter?.emoji
        return [emoji, filter?.title].compactMap { $0 }.joined(separator: " ")
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
            checkmark.isHidden = !isSelected
            filterLabel.text = filterTitle
            updateSelectedStyle()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        filterLabel.font = CollabsableHeaderFilterCollectionViewCell.font
        if #available(iOS 13.0, *) {
            checkmark.image = UIImage(systemName: "checkmark")
        } else {
            checkmark.image = UIImage.gridicon(.checkmark)
        }
        checkmark.tintColor = checkmarkTintColor
        updateSelectedStyle()

        filterLabel.isGhostableDisabled = true
        checkmark.isGhostableDisabled = true
        pillBackgroundView.layer.masksToBounds = true
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
            pillBackgroundView.backgroundColor = isSelected ? .black : .gray(.shade0)
        }

        if #available(iOS 13.0, *), traitCollection.userInterfaceStyle == .dark {
            filterLabel.textColor = isSelected ? .darkText : .white
        } else {
            filterLabel.textColor = isSelected ? .white : .darkText
        }
    }
}

extension CollabsableHeaderFilterCollectionViewCell: GhostableView {
    func ghostAnimationWillStart() {
        filterLabel.text = ""
        pillBackgroundView.startGhostAnimation(style: GhostCellStyle.muriel)
    }
}
