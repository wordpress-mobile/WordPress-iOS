import UIKit

final class ReferrerDetailsCell: UITableViewCell {
    private let referrerLabel = UILabel()
    private let viewsLabel = UILabel()
    private let separatorView = UIView()
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
extension ReferrerDetailsCell {
    func configure(isLast: Bool) {
        referrerLabel.text = "Test"
        viewsLabel.text = "123"
        separatorView.isHidden = !isLast
    }
}

// MARK: - Private methods
private extension ReferrerDetailsCell {
    func setupViews() {
        setupReferrerLabel()
        setupViewsLabel()
        setupSeparatorView()
    }

    func setupReferrerLabel() {
        WPStyleGuide.Stats.configureLabelAsLink(referrerLabel)
        referrerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(referrerLabel)
        NSLayoutConstraint.activate([
            referrerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.standardCellSpacing),
            referrerLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func setupViewsLabel() {
        WPStyleGuide.Stats.configureLabelAsChildRowTitle(viewsLabel)
        viewsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(viewsLabel)
        NSLayoutConstraint.activate([
            viewsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: referrerLabel.trailingAnchor, constant: Constants.standardCellSpacing),
            viewsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.standardCellSpacing),
            viewsLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func setupSeparatorView() {
        separatorView.backgroundColor = WPStyleGuide.Stats.separatorColor
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)
        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: WPStyleGuide.Stats.separatorHeight)
        ])
    }
}
