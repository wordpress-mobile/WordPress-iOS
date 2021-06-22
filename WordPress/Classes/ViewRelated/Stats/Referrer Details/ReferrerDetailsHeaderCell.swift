import UIKit

final class ReferrerDetailsHeaderCell: UITableViewCell {
    private let referrerLabel = UILabel()
    private let viewsLabel = UILabel()
    private typealias Constants = ReferrerDetailsTableViewController.Constants

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
        setupReferrerLabel()
        setupViewsLabel()
    }

    func setupReferrerLabel() {
        WPStyleGuide.Stats.configureLabelAsSubtitle(referrerLabel)
        referrerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(referrerLabel)
        NSLayoutConstraint.activate([
            referrerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.standardCellSpacing),
            referrerLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func setupViewsLabel() {
        WPStyleGuide.Stats.configureLabelAsSubtitle(viewsLabel)
        viewsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(viewsLabel)
        NSLayoutConstraint.activate([
            viewsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.standardCellSpacing),
            viewsLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
