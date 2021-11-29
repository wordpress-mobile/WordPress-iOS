import UIKit

final class LoginEpilogueChooseSiteTableViewCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private Methods
private extension LoginEpilogueChooseSiteTableViewCell {
    func setupViews() {
        backgroundColor = .basicBackground
        selectionStyle = .none
        setupTitleLabel()
        setupSubtitleLabel()
        setupStackView()
    }

    func setupTitleLabel() {
        titleLabel.text = NSLocalizedString("Choose a site to open.", comment: "A text for title label on Login epilogue screen")
        titleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .medium)
    }

    func setupSubtitleLabel() {
        subtitleLabel.text = NSLocalizedString("You can switch sites at any time.", comment: "A text for subtitle label on Login epilogue screen")
        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        subtitleLabel.textColor = .secondaryLabel
    }

    func setupStackView() {
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = Constants.stackViewSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubviews([titleLabel, subtitleLabel])
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.stackViewHorizontalMargin),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.stackViewHorizontalMargin),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.stackViewTopMargin),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.stackViewBottomMargin)
        ])
    }

    private enum Constants {
        static let stackViewSpacing: CGFloat = 4.0
        static let stackViewHorizontalMargin: CGFloat = 20.0
        static let stackViewTopMargin: CGFloat = 16.0
        static let stackViewBottomMargin: CGFloat = 26.0
    }
}
