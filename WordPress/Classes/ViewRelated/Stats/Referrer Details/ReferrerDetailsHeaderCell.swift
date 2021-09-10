import UIKit

final class ReferrerDetailsHeaderCell: UITableViewCell {
    private let referrerLabel = UILabel()
    private let viewsLabel = UILabel()
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
extension ReferrerDetailsHeaderCell {
    func configure(with section: StatSection) {
        referrerLabel.text = section.itemSubtitle
        viewsLabel.text = section.dataSubtitle
    }
}

// MARK: - Private methods
private extension ReferrerDetailsHeaderCell {
    func setupViews() {
        isUserInteractionEnabled = false
        separatorInset = .zero
        backgroundColor = Style.cellBackgroundColor
        setupReferrerLabel()
        setupViewsLabel()
    }

    func setupReferrerLabel() {
        Style.configureLabelAsSubtitle(referrerLabel)
        referrerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(referrerLabel)
        NSLayoutConstraint.activate([
            referrerLabel.leadingAnchor.constraint(equalTo: safeLeadingAnchor, constant: Style.ReferrerDetails.standardCellSpacing),
            referrerLabel.topAnchor.constraint(equalTo: topAnchor, constant: Style.ReferrerDetails.headerCellVerticalPadding),
            referrerLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Style.ReferrerDetails.headerCellVerticalPadding)
        ])
    }

    func setupViewsLabel() {
        Style.configureLabelAsSubtitle(viewsLabel)
        viewsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(viewsLabel)
        NSLayoutConstraint.activate([
            viewsLabel.trailingAnchor.constraint(equalTo: safeTrailingAnchor, constant: -Style.ReferrerDetails.standardCellSpacing),
            viewsLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
