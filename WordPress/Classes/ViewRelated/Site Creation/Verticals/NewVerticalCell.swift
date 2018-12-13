import UIKit
import Gridicons

final class NewVerticalCell: UITableViewCell, SiteVerticalPresenter {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!

    private struct Strings {
        static let newVerticalSubtitle = NSLocalizedString("Custom category", comment: "Placeholder for new site types when creating a new site")
    }

    var vertical: SiteVertical? {
        didSet {
            title.text = vertical?.title
            subtitle.text = Strings.newVerticalSubtitle
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleTitle()
        styleSubtitle()
        styleAccessoryView()
    }

    override func prepareForReuse() {
        title.text = ""
    }

    private func styleTitle() {
        WPStyleGuide.configureLabel(title, textStyle: .body, symbolicTraits: .traitItalic)
        title.textColor = WPStyleGuide.darkGrey()
    }

    private func styleSubtitle() {
        subtitle.font = WPFontManager.systemRegularFont(ofSize: 15.0)
        subtitle.textColor = WPStyleGuide.grey()
    }

    private func styleAccessoryView() {
        let accessoryImage = Gridicon.iconOfType(.chevronRight).imageWithTintColor(WPStyleGuide.greyLighten20())
        accessoryView = UIImageView(image: accessoryImage)
    }
}
