import UIKit

final class ReferrerDetailsSpamActionCell: UITableViewCell {
    private let actionLabel = UILabel()
    private let separatorView = UIView()
    private let loader = UIActivityIndicatorView(style: .medium)
    private typealias Style = WPStyleGuide.Stats
    private var markAsSpam: Bool = false

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
    func configure(markAsSpam: Bool, isLoading: Bool) {
        isLoading ? loader.startAnimating() : loader.stopAnimating()
        actionLabel.isHidden = isLoading

        if markAsSpam {
            actionLabel.text = NSLocalizedString("Mark as spam", comment: "Action title for marking referrer as spam")
            actionLabel.textColor = Style.negativeColor
        } else {
            actionLabel.text = NSLocalizedString("Mark as not spam", comment: "Action title for unmarking referrer as spam")
            actionLabel.textColor = Style.positiveColor
        }

        self.markAsSpam = markAsSpam
        prepareForVoiceOver()
    }
}

// MARK: - Accessible
extension ReferrerDetailsSpamActionCell: Accessible {
    func prepareForVoiceOver() {
        isAccessibilityElement = true
        if let text = actionLabel.text {
            accessibilityLabel = text
        }
        accessibilityTraits = [.button]

        let markHint = NSLocalizedString("Tap to mark referrer as spam.", comment: "Accessibility hint for referrer action row.")
        let unmarkHint = NSLocalizedString("Tap to mark referrer as not spam.", comment: "Accessibility hint for referrer action row.")
        accessibilityHint = markAsSpam ? markHint : unmarkHint
    }
}

// MARK: - Private methods
private extension ReferrerDetailsSpamActionCell {
    func setupViews() {
        separatorInset = .zero
        selectionStyle = .none
        backgroundColor = Style.cellBackgroundColor
        setupActionLabel()
        setupLoader()
        setupSeparatorView()
    }

    func setupActionLabel() {
        actionLabel.textAlignment = .center
        actionLabel.font = WPStyleGuide.tableviewTextFont()
        actionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(actionLabel)
        NSLayoutConstraint.activate([
            actionLabel.leadingAnchor.constraint(equalTo: safeLeadingAnchor, constant: Style.ReferrerDetails.standardCellSpacing),
            actionLabel.trailingAnchor.constraint(equalTo: safeTrailingAnchor, constant: -Style.ReferrerDetails.standardCellSpacing),
            actionLabel.topAnchor.constraint(equalTo: topAnchor, constant: Style.ReferrerDetails.standardCellVerticalPadding),
            actionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Style.ReferrerDetails.standardCellVerticalPadding)
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
