import UIKit

final class ReferrerDetailsSpamActionCell: UITableViewCell {
    private let actionLabel = UILabel()
    private let separatorView = UIView()

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
            actionLabel.text = NSLocalizedString("Mark as spam", comment: "Action title for marking referrer as spam")
            actionLabel.textColor = WPStyleGuide.Stats.negativeColor
        } else {
            actionLabel.text = NSLocalizedString("Mark as not spam", comment: "Action title for unmarking referrer as spam")
            actionLabel.textColor = WPStyleGuide.Stats.positiveColor
        }
    }
}

// MARK: - Private methods
private extension ReferrerDetailsSpamActionCell {
    func setupViews() {
        separatorInset = .zero
        setupActionLabel()
        setupSeparatorView()
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

    func setupSeparatorView() {
        separatorView.backgroundColor = WPStyleGuide.Stats.separatorColor
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: WPStyleGuide.Stats.separatorHeight)
        ])
    }
}
