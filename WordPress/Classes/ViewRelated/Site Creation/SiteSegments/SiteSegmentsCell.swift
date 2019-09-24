import UIKit
import Alamofire
import Gridicons
import WordPressKit


private extension String {
    func hexAsColor() -> UIColor? {
        return UIColor(hexString: self)
    }
}

private extension SiteSegment {
    var iconTintColor: UIColor? {
        return self.iconColor?.hexAsColor()
    }
}

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
                    self?.icon.tintColor = .listIcon
                    self?.icon.image = tintedImage
                }, failure: nil)
            }
        }
    }

    func set(segment: SiteSegment) {
        title.text = segment.title
        subtitle.text = segment.subtitle
        if let segmentIcon = segment.icon {
            icon.downloadImage(from: segmentIcon)
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
        title.text = ""
        subtitle.text = ""
        icon.image = nil
    }

    private func styleBackground() {
        backgroundColor = .listForeground
    }

    private func styleTitle() {
        title.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        title.textColor = .text
        title.adjustsFontForContentSizeCategory = true
    }

    private func styleSubtitle() {
        subtitle.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular)
        subtitle.textColor = .textSubtle
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
