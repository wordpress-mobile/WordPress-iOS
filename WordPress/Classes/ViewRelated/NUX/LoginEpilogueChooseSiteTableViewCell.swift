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
        titleLabel.font = WPStyleGuide.fontForTextStyle(.callout, fontWeight: .medium)
    }

    func setupSubtitleLabel() {
        subtitleLabel.text = NSLocalizedString("You can switch sites at any time.", comment: "A text for subtitle label on Login epilogue screen")
        subtitleLabel.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
        subtitleLabel.textColor = .secondaryLabel
    }

    func setupStackView() {
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubviews([titleLabel, subtitleLabel])
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -26)
        ])
    }
}
