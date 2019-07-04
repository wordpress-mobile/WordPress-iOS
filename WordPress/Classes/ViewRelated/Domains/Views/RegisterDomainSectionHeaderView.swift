import UIKit

class RegisterDomainSectionHeaderView: UITableViewHeaderFooterView {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    static let identifier = "RegisterDomainSectionHeaderView"

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline,
                                                        fontWeight: .semibold)
        titleLabel.textColor = .neutral(shade: .shade70)
        titleLabel.numberOfLines = 0

        descriptionLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        descriptionLabel.textColor = .neutral(shade: .shade70)
        descriptionLabel.numberOfLines = 0
        contentView.backgroundColor = .neutral(shade: .shade5)
    }

    func setTitle(_ title: String?) {
        titleLabel.text = title
    }

    func setDescription(_ description: String?) {
        descriptionLabel.text = description
    }

}
