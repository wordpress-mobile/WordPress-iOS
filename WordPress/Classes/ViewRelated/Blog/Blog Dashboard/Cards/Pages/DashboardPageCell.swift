import UIKit

class DashboardPageCell: UITableViewCell, Reusable {

    // MARK: Variables

    // MARK: Views

    lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.mainStackViewSpacing
        stackView.directionalLayoutMargins = Metrics.mainStackViewLayoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addBottomBorder(withColor: Colors.separatorColor, leadingMargin: Metrics.separatorLeadingMargin)
        stackView.addArrangedSubviews([titleLabel, detailsStackView])
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .bold)
        label.numberOfLines = 1
        label.textAlignment = .natural
        label.textColor = .text
        return label
    }()

    lazy var detailsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Metrics.detailsStackViewSpacing
        stackView.addArrangedSubviews([statusView, dateLabel])
        return stackView
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.regularTextFont()
        label.numberOfLines = 1
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var statusView = PageStatusView()

    // MARK: Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: View Lifecycle

    override func prepareForReuse() {
        // TODO: Implement this if needed
    }

    // MARK: Public Functions

    func configure(using page: Page) {
        titleLabel.text = page.titleForDisplay()
        statusView.configure(for: page.status)
    }

    // MARK: Helpers

    private func commonInit() {
        setupViews()
    }

    private func setupViews() {
        contentView.addSubview(mainStackView)
        contentView.pinSubviewToAllEdges(mainStackView)
    }

}

private extension DashboardPageCell {
    enum Metrics {
        static let mainStackViewSpacing: CGFloat = 6
        static let detailsStackViewSpacing: CGFloat = 6
        static let mainStackViewLayoutMargins: NSDirectionalEdgeInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
        static let separatorLeadingMargin: CGFloat = 16
    }

    enum Colors {
        static let separatorColor = UIColor(red: 0.235, green: 0.235, blue: 0.263, alpha: 0.36)
    }
}

fileprivate class PageStatusView: UIView {

    enum PageStatus {
        case published
        case scheduled
        case draft

        var title: String {
            switch self {
            case .published:
                return Strings.publishedTitle
            case .scheduled:
                return Strings.scheduledTitle
            case .draft:
                return Strings.draftTitle
            }
        }

        var icon: UIImage? {
            switch self {
            case .published:
                return UIImage(named: "icon.globe")
            case .scheduled:
                return UIImage(named: "icon.calendar")
            case .draft:
                return UIImage(named: "icon.verse")
            }
        }
    }

    // MARK: Views

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .secondaryLabel
        imageView.heightAnchor.constraint(equalToConstant: Metrics.iconImageViewSize).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: Metrics.iconImageViewSize).isActive = true
        addSubview(imageView)
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.regularTextFont()
        label.numberOfLines = 1
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: Public Functions

    func configure(for status: BasePost.Status?) {
        guard let pageStatus = status?.pageStatus else {
            return
        }
        titleLabel.text = pageStatus.title
        iconImageView.image = pageStatus.icon
    }

    // MARK: Helpers

    private func commonInit() {
        applyStyles()
        setupViews()
    }

    private func applyStyles() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = Metrics.cornerRadius
    }

    private func setupViews() {
        addSubviews([iconImageView, titleLabel])

        // Icon Image View Constraints
        iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.iconLeadingSpace).isActive = true
        iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        // Title label Constraints
        titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: Metrics.titleLabelMargins.leading).isActive = true
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.titleLabelMargins.top).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Metrics.titleLabelMargins.bottom).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.titleLabelMargins.trailing).isActive = true
    }

    private enum Metrics {
        static let iconLeadingSpace: CGFloat = 4
        static let titleLabelMargins: NSDirectionalEdgeInsets = .init(top: 2, leading: 4, bottom: 2, trailing: 8)
        static let iconImageViewSize: CGFloat = 16
        static let cornerRadius: CGFloat = 2
    }

    private enum Strings {
        static let publishedTitle = NSLocalizedString("dashboardCard.pages.cell.status.publish",
                                                      value: "Published",
                                                      comment: "Title of label marking a published page")
        static let scheduledTitle = NSLocalizedString("dashboardCard.pages.cell.status.schedule",
                                                      value: "Scheduled",
                                                      comment: "Title of label marking a scheduled page")
        static let draftTitle = NSLocalizedString("dashboardCard.pages.cell.status.draft",
                                                  value: "Draft",
                                                  comment: "Title of label marking a draft page")
    }

}

fileprivate extension BasePost.Status {
    var pageStatus: PageStatusView.PageStatus? {
        switch self {
        case .draft:
            return .draft
        case .pending:
            return .draft
        case .publishPrivate:
            return .published
        case .publish:
            return .published
        case .scheduled:
            return .scheduled
        case .trash:
            return nil
        case .deleted:
            return nil
        }
    }
}
