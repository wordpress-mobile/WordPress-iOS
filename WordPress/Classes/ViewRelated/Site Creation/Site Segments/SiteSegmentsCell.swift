import UIKit
import Gridicons
import WordPressKit
import WordPressShared

final class SiteSegmentsCell: UITableViewCell, ModelSettableCell {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!

    var model: SiteSegment? {
        didSet {
            title.text = model?.title
            subtitle.text = model?.subtitle
            if let modelIcon = model?.icon {
                icon.downloadImage(from: modelIcon, placeholderImage: nil, success: { [weak self] downloadedImage in
                    let tintedImage = downloadedImage.withRenderingMode(.alwaysTemplate)
                    self?.icon.tintColor = .secondaryLabel
                    self?.icon.image = tintedImage
                }, failure: nil)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        styleBackground()
        styleTitle()
        styleSubtitle()
        styleAccessoryView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        title.text = ""
        subtitle.text = ""
        icon.image = nil
    }

    private func styleBackground() {
        backgroundColor = .secondarySystemGroupedBackground
    }

    private func styleTitle() {
        title.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        title.textColor = .label
        title.adjustsFontForContentSizeCategory = true
    }

    private func styleSubtitle() {
        subtitle.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular)
        subtitle.textColor = .secondaryLabel
        subtitle.adjustsFontForContentSizeCategory = true
    }

    private func styleAccessoryView() {
        accessoryType = .disclosureIndicator
    }
}

extension SiteSegmentsCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            preferredContentSizeDidChange()
        }
    }

    func preferredContentSizeDidChange() {
        // Title needs to be forced to reset its style, otherwise the types do not change
        styleTitle()
    }
}
