import UIKit
import Gridicons

/// This cell describes a server-vended `SiteVertical`.
///
final class VerticalsCell: UITableViewCell, SiteVerticalPresenter {
    @IBOutlet weak var title: UILabel!

    var vertical: SiteVertical? {
        didSet {
            title.text = vertical?.title
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleTitle()
    }

    override func prepareForReuse() {
        title.text = ""
    }

    private func styleTitle() {
        title.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        title.textColor = .text
        title.adjustsFontForContentSizeCategory = true
    }
}

extension VerticalsCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            preferredContentSizeDidChange()
        }
    }

    func preferredContentSizeDidChange() {
        styleTitle()
    }
}
