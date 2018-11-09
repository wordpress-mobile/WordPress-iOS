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
    }

    override func prepareForReuse() {
        title.text = ""
        subtitle.text = ""
        icon.image = nil
    }

    private func styleTitle() {

    }

    private func styleSubtitle() {

    }
}
