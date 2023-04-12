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

        var icon: UIImage {
            return UIImage()
        }
    }

    // MARK: Variables

    // MARK: Views

    lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.backgroundColor = .secondarySystemBackground
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = Metrics.mainStackViewSpacing
        stackView.directionalLayoutMargins = Metrics.mainStackViewLayoutMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubviews([titleLabel]) // TODO: Add views
        return stackView
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
    }

    // MARK: Helpers

    private func commonInit() {
        setupViews()
    }

    private func setupViews() {
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)
    }

    private enum Metrics {
        static let mainStackViewSpacing: CGFloat = 6
        static let mainStackViewLayoutMargins: NSDirectionalEdgeInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 8)
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
