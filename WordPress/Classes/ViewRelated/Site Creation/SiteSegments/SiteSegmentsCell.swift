import UIKit
import Alamofire
import Gridicons

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
                    if let tintColor = self?.model?.iconColor {
                        self?.icon.tintColor = tintColor
                    }
                    self?.icon.image = tintedImage
                }, failure: nil)
            }
        }
    }

    func set(segment: SiteSegment) {
        title.text = segment.title
        subtitle.text = segment.subtitle
        icon.setImageWith(segment.icon)
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
        backgroundColor = .white
    }

    private func styleTitle() {
        title.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        title.textColor = WPStyleGuide.darkGrey()
    }

    private func styleSubtitle() {
        subtitle.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .regular)
        subtitle.textColor = WPStyleGuide.darkGrey()
    }

    private func styleAccessoryView() {
        let accessoryImage = Gridicon.iconOfType(.chevronRight).imageWithTintColor(WPStyleGuide.greyLighten20())
        accessoryView = UIImageView(image: accessoryImage)
    }
}
