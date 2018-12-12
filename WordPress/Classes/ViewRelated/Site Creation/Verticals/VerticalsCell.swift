import UIKit

class VerticalsCell: UITableViewCell, ModelSettableCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!

    private struct Constants {
        static let verticalSubtitle = ""
        static let newVerticalSubtitle = NSLocalizedString("Custom category", comment: "Placeholder for new site types when creating a new site")
    }

    var model: SiteVertical? {
        didSet {
            title.text = model?.title
            if let isNew = model?.isNew, isNew == true {
                configureAsNew()
            } else {
                configureAsRegular()
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleTitle()
        styleSubtitle()
    }

    override func prepareForReuse() {
        title.text = ""
        subtitle.text = ""

        styleTitle()
        styleSubtitle()
    }

    private func styleTitle() {
        title.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        title.textColor = WPStyleGuide.darkGrey()
    }

    private func styleSubtitle() {
        subtitle.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        subtitle.textColor = WPStyleGuide.grey()
    }

    private func configureAsNew() {
        subtitle.isHidden = false
        subtitle.text = Constants.newVerticalSubtitle

        WPStyleGuide.configureLabel(title, textStyle: .body, symbolicTraits: .traitItalic)
    }

    private func configureAsRegular() {
        subtitle.isHidden = true
        subtitle.text = Constants.verticalSubtitle
    }
}
