import UIKit

final class DashboardQuickActionCell: UITableViewCell {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let detailsLabel = UILabel()
    private let spotlightView = QuickStartSpotlightView()
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
        startObservingQuickStart()
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
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(stackView, insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))

        spotlightView.isHidden = true
        addSubview(spotlightView)
        spotlightView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spotlightView.centerYAnchor.constraint(equalTo: centerYAnchor),
            spotlightView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 16)
        ])
    }

    func configure(_ viewModel: DashboardQuickActionItemViewModel) {
        self.viewModel = viewModel

        titleLabel.text = viewModel.title
        iconView.image = viewModel.image?.withRenderingMode(.alwaysTemplate)
        detailsLabel.text = viewModel.details
        spotlightView.isHidden = true
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
            separatorInset = UIEdgeInsets(top: 0, left: titleLabelFrame.origin.x, bottom: 0, right: 0)
        }
    }

    private func startObservingQuickStart() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickStartTourElementChangedNotification(_:)), name: .QuickStartTourElementChangedNotification, object: nil)
    }

    @objc private func handleQuickStartTourElementChangedNotification(_ notification: Foundation.Notification) {
        guard let info = notification.userInfo,
              let element = info[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement,
              element == viewModel?.tourElement,
              QuickStartTourGuide.shared.entryPointForCurrentTour == .blogDashboard
        else {
            spotlightView.isHidden = true
            return
        }
        spotlightView.isHidden = false
    }
}
