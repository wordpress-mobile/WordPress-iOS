import UIKit

final class ReferrerDetailsCell: UITableViewCell {
    private let referrerLabel = UILabel()
    private let viewsLabel = UILabel()
    private let separatorView = UIView()
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
extension ReferrerDetailsCell {
    func configure(data: ReferrerDetailsRow.DetailsData, isLast: Bool) {
        referrerLabel.text = data.name
        viewsLabel.text = data.views
        separatorView.isHidden = !isLast
        prepareForVoiceOver()
    }
}

// MARK: - Accessible
extension ReferrerDetailsCell: Accessible {
    func prepareForVoiceOver() {
        isAccessibilityElement = true
        if let referrer = referrerLabel.text,
           let views = viewsLabel.text {
            accessibilityLabel = "\(referrer), \(views)"
        }
        accessibilityTraits = [.staticText, .button]
        accessibilityHint = NSLocalizedString("Tap to display referrer web page.", comment: "Accessibility hint for referrer details row.")
    }
}

// MARK: - Private methods
private extension ReferrerDetailsCell {
    func setupViews() {
        selectionStyle = .none
        backgroundColor = Style.cellBackgroundColor
        setupReferrerLabel()
        setupViewsLabel()
        setupSeparatorView()
    }

    func setupReferrerLabel() {
        Style.configureLabelAsLink(referrerLabel)
        referrerLabel.font = WPStyleGuide.tableviewTextFont()
        referrerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(referrerLabel)
        NSLayoutConstraint.activate([
            referrerLabel.leadingAnchor.constraint(equalTo: safeLeadingAnchor, constant: Style.ReferrerDetails.standardCellSpacing),
            referrerLabel.topAnchor.constraint(equalTo: topAnchor, constant: Style.ReferrerDetails.standardCellVerticalPadding),
            referrerLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Style.ReferrerDetails.standardCellVerticalPadding)
        ])
    }

    func setupViewsLabel() {
        Style.configureLabelAsChildRowTitle(viewsLabel)
        viewsLabel.font = WPStyleGuide.tableviewTextFont()
        viewsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        viewsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(viewsLabel)
        NSLayoutConstraint.activate([
            viewsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: referrerLabel.trailingAnchor, constant: Style.ReferrerDetails.standardCellSpacing),
            viewsLabel.trailingAnchor.constraint(equalTo: safeTrailingAnchor, constant: -Style.ReferrerDetails.standardCellSpacing),
            viewsLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func setupSeparatorView() {
        separatorView.backgroundColor = Style.separatorColor
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: Style.separatorHeight)
        ])
    }
}
