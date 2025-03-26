import UIKit
import WordPressShared

class RegisterDomainSectionHeaderView: UITableViewHeaderFooterView {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    static let identifier = "RegisterDomainSectionHeaderView"

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline,
                                                        fontWeight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.numberOfLines = 0

        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        contentView.backgroundColor = .systemGroupedBackground
    }

    func setTitle(_ title: String?) {
        titleLabel.text = title
    }

    func setDescription(_ description: String?) {
        descriptionLabel.text = description
    }

}
