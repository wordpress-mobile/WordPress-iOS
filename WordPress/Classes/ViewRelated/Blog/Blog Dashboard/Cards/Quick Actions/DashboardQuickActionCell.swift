import UIKit
import WordPressUI

final class DashboardQuickActionCell: UITableViewCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let detailsLabel = UILabel()
    private var viewModel: DashboardQuickActionItemViewModel?

    var isSeparatorHidden = false {
        didSet {
            guard oldValue != isSeparatorHidden else { return }
            refreshSeparator()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        createView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createView() {
        titleLabel.font = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .medium)
        titleLabel.adjustsFontForContentSizeCategory = true

        iconView.tintColor = .label

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 8).isActive = true

        detailsLabel.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        detailsLabel.textColor = .secondaryLabel
        detailsLabel.adjustsFontForContentSizeCategory = true

        let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel, spacer, detailsLabel])
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.isUserInteractionEnabled = false

        contentView.addSubview(stackView)
        let vertical: CGFloat = if #available(iOS 26, *) { 14 } else { 12 }
        stackView.pinEdges(insets: UIEdgeInsets(horizontal: 16, vertical: vertical))
    }

    func configure(_ viewModel: DashboardQuickActionItemViewModel) {
        self.viewModel = viewModel

        titleLabel.text = viewModel.title
        iconView.image = viewModel.image?.withRenderingMode(.alwaysTemplate)
        detailsLabel.text = viewModel.details
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        refreshSeparator()
    }

    private func refreshSeparator() {
        if isSeparatorHidden {
            separatorInset = UIEdgeInsets(top: 0, left: bounds.width, bottom: 0, right: 0)
        } else {
            let titleLabelFrame = contentView.convert(titleLabel.frame, from: titleLabel.superview)
            separatorInset = UIEdgeInsets(top: 0, left: traitCollection.layoutDirection == .rightToLeft ? contentView.bounds.width - titleLabelFrame.maxX : titleLabelFrame.origin.x, bottom: 0, right: 0)
        }
    }
}
