import UIKit

final class SiteSegmentsCell: UITableViewCell, ModelSettableCell {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!

    var model: SiteSegment? {
        didSet {
            title.text = model?.title
            subtitle.text = model?.subtitle
            if let modelIcon = model?.icon {
                icon.setImageWith(modelIcon)
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
        styleTitle()
        styleSubtitle()
        styleAccessoryView()
    }

    override func prepareForReuse() {
        title.text = ""
        subtitle.text = ""
        icon.image = nil
    }

    private func styleTitle() {
        title.font = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .semibold)
        title.textColor = WPStyleGuide.darkGrey()
    }

    private func styleSubtitle() {
        subtitle.font = WPStyleGuide.fontForTextStyle(.caption1, fontWeight: .regular)
        subtitle.textColor = WPStyleGuide.darkGrey()
    }

    private func styleAccessoryView() {
        accessoryType = .disclosureIndicator
    }
}
