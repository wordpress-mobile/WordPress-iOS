import UIKit

class RegisterDomainSectionHeaderView: UITableViewHeaderFooterView {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    static let identifier = "RegisterDomainSectionHeaderView"

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline,
                                                        fontWeight: .semibold)
        titleLabel.textColor = WPStyleGuide.darkGrey()
        titleLabel.numberOfLines = 0

        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        descriptionLabel.textColor = WPStyleGuide.darkGrey()
        descriptionLabel.numberOfLines = 0
    }

    func setTitle(_ title: String?) {
        titleLabel.text = title
    }

    func setDescription(_ description: String?) {
        descriptionLabel.text = description
    }

}
