import UIKit

class ReaderRelatedPostsCollectionViewCell: UICollectionViewCell, NibReusable {

    @IBOutlet weak var featuredImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    private func applyStyles() {
        featuredImageView.clipsToBounds = true
        featuredImageView.layer.cornerRadius = Constants.cornerRadius

        titleLabel.numberOfLines = 0
        titleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        titleLabel.textColor = .text
    }

    func configure() {
        featuredImageView.backgroundColor = .green // FIXME
        titleLabel.text = "Placeholder title" // FIXME
    }

    private enum Constants {
        static let cornerRadius: CGFloat = 4
    }
}
