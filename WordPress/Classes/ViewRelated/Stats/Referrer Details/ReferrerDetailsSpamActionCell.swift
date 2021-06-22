import UIKit

final class ReferrerDetailsSpamActionCell: UITableViewCell {
    private let actionLabel = UILabel()
    private let separatorView = UIView()
    private let loader = UIActivityIndicatorView(style: .medium)
    private typealias Style = WPStyleGuide.Stats

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
            actionLabel.textColor = Style.negativeColor
        } else {
            actionLabel.text = NSLocalizedString("Mark as not spam", comment: "Action title for unmarking referrer as spam")
            actionLabel.textColor = Style.positiveColor
        }
    }
}

// MARK: - Private methods
private extension ReferrerDetailsSpamActionCell {
    func setupViews() {
        separatorInset = .zero
        selectionStyle = .none
        setupActionLabel()
        setupLoader()
        setupSeparatorView()
    }

    func setupActionLabel() {
        actionLabel.textAlignment = .center
        actionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(actionLabel)
        NSLayoutConstraint.activate([
            actionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Style.ReferrerDetails.standardCellSpacing),
            actionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Style.ReferrerDetails.standardCellSpacing),
            actionLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func setupLoader() {
        loader.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loader)
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func setupSeparatorView() {
        separatorView.backgroundColor = Style.separatorColor
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: Style.separatorHeight)
        ])
    }
}
