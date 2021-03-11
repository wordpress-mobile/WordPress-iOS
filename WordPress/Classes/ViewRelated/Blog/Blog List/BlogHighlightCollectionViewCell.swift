import UIKit

class BlogHighlightCollectionViewCell: UICollectionViewCell, NibReusable {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
        applyAccessibility()
    }

    func configure(with highlight: BlogHighlight) {
        imageView.image = highlight.icon
        label.text = highlight.title
    }

    private func applyStyles() {
        layer.backgroundColor = UIColor.listBackground.cgColor

        label.font = WPStyleGuide.fontForTextStyle(.footnote)
        label.textColor = .text
    }

    private func applyAccessibility() {
        guard let label = self.label else {
            return
        }

        label.accessibilityTraits = .staticText
        label.isAccessibilityElement = true
        accessibilityElements = [label]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard layer.cornerRadius == 0 else {
            return
        }
        layer.cornerRadius = bounds.height / 2
    }

}
