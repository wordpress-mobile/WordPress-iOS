import UIKit

final class ReferrerDetailsCell: UITableViewCell {
    private let referrerLabel = UILabel()
    private let viewsLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Public Methods
extension ReferrerDetailsCell {
    func configure(isLast: Bool) {
        referrerLabel.text = "Test"
        viewsLabel.text = "123"
        if isLast {
            separatorInset = .zero
        }
    }
}

// MARK: - Private methods
private extension ReferrerDetailsCell {
    func setupViews() {
        setupReferrerLabel()
        setupViewsLabel()
    }

    func setupReferrerLabel() {
        WPStyleGuide.Stats.configureLabelAsLink(referrerLabel)
        referrerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(referrerLabel)
        NSLayoutConstraint.activate([
            referrerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            referrerLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func setupViewsLabel() {
        WPStyleGuide.Stats.configureLabelAsChildRowTitle(viewsLabel)
        viewsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(viewsLabel)
        NSLayoutConstraint.activate([
            viewsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: referrerLabel.trailingAnchor, constant: 16),
            viewsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            viewsLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
