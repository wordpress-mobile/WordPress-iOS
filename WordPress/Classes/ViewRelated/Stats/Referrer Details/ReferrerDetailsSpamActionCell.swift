import UIKit

final class ReferrerDetailsSpamActionCell: UITableViewCell {
    private let actionLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Public Methods
extension ReferrerDetailsSpamActionCell {
    func configure(markAsSpam: Bool) {
        if markAsSpam {
            actionLabel.text = "Mark as spam"
            actionLabel.textColor = WPStyleGuide.Stats.negativeColor
        } else {
            actionLabel.text = "Mark as not spam"
            actionLabel.textColor = WPStyleGuide.Stats.positiveColor
        }
    }
}

// MARK: - Private methods
private extension ReferrerDetailsSpamActionCell {
    func setupViews() {
        separatorInset = .zero
        setupActionLabel()
    }

    func setupActionLabel() {
        actionLabel.textAlignment = .center
        actionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(actionLabel)
        NSLayoutConstraint.activate([
            actionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            actionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            actionLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
