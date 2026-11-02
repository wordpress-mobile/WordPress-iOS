import UIKit
import Gridicons
import WordPressShared

class StatsCellHeader: UITableViewCell, Accessible {

    // MARK: - Properties

    private let headerLabel = UILabel.makeStatsLabel(
        text: "CELL HEADER LABEL",
        textStyle: .footnote,
        textColor: UIColor(white: 0.667, alpha: 1),
        textAlignment: .left
    )

    private let manageInsightButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let manageInsightImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
        return imageView
    }()

    private var stackViewTopConstraint: NSLayoutConstraint!
    private var stackViewHeightConstraint: NSLayoutConstraint!

    private typealias Style = WPStyleGuide.Stats
    private var statSection: StatSection?
    private weak var siteStatsInsightsDelegate: SiteStatsInsightsDelegate?
    private let defaultStackViewTopConstraint: CGFloat = 20
    private let defaultStackViewHeightConstraint: CGFloat = 36
    private var adjustHeightForPostStats = false
    private let emptyPostStatsHeight: CGFloat = 20

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        clipsToBounds = true
        preservesSuperviewLayoutMargins = true
        contentView.clipsToBounds = true
        contentView.contentMode = .center
        contentView.preservesSuperviewLayoutMargins = true
        contentView.insetsLayoutMarginsFromSafeArea = false

        let stackView = UIStackView(arrangedSubviews: [headerLabel, manageInsightImageView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = 10
        contentView.addSubview(stackView)

        manageInsightButton.addTarget(self, action: #selector(manageInsightButtonPressed), for: .touchUpInside)
        contentView.addSubview(manageInsightButton)

        stackViewTopConstraint = stackView.topAnchor.constraint(
            equalTo: contentView.topAnchor,
            constant: defaultStackViewTopConstraint
        )
        stackViewHeightConstraint = stackView.heightAnchor.constraint(equalToConstant: defaultStackViewHeightConstraint)
        let bottomConstraint = contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        bottomConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            stackViewTopConstraint,
            stackViewHeightConstraint,
            bottomConstraint,
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 16),

            manageInsightImageView.widthAnchor.constraint(equalToConstant: 24),
            manageInsightImageView.widthAnchor.constraint(equalTo: manageInsightImageView.heightAnchor),

            manageInsightButton.leadingAnchor.constraint(equalTo: headerLabel.trailingAnchor),
            manageInsightButton.topAnchor.constraint(equalTo: stackView.topAnchor),
            manageInsightButton.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: manageInsightButton.trailingAnchor, constant: 5)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(statSection: StatSection? = nil, siteStatsInsightsDelegate: SiteStatsInsightsDelegate? = nil) {
        self.siteStatsInsightsDelegate = siteStatsInsightsDelegate
        self.statSection = statSection
        headerLabel.text = statSection?.title ?? ""
        self.adjustHeightForPostStats = (statSection == .postStatsGraph)
        prepareForVoiceOver()
        applyStyles()
    }

    func prepareForVoiceOver() {
        headerLabel.isAccessibilityElement = (headerLabel.text?.isEmpty == false)
        headerLabel.accessibilityElementsHidden = (headerLabel.text?.isEmpty == true)
        headerLabel.accessibilityLabel = headerLabel.text
        headerLabel.accessibilityTraits = .header

        manageInsightImageView.isAccessibilityElement = false
        manageInsightButton.isAccessibilityElement = !manageInsightButton.isHidden
        manageInsightButton.accessibilityElementsHidden = manageInsightButton.isHidden
        manageInsightButton.accessibilityTraits = .button
        manageInsightButton.accessibilityLabel = NSLocalizedString(
            "Manage Insight",
            comment: "Accessibility label for button that displays Manage Insight options."
        )
        manageInsightButton.accessibilityHint = NSLocalizedString(
            "Select to manage this Insight.",
            comment: "Accessibility hint for Manage Insight button."
        )

        accessibilityElements = [headerLabel, manageInsightButton].compactMap { $0 }
    }
}

private extension StatsCellHeader {

    // MARK: - Configure

    func applyStyles() {
        Style.configureHeaderCell(self)
        Style.configureLabelAsHeader(headerLabel)
        configureManageInsightButton()
        updateStackView()
    }

    func updateStackView() {
        // Only show the top padding if there is actually a label.
        stackViewTopConstraint.constant = (headerLabel.text ?? "").isEmpty ? 0 : defaultStackViewTopConstraint

        // Adjust the height if displaying on Post Stats with no title.
        stackViewHeightConstraint.constant =
            adjustHeightForPostStats ? emptyPostStatsHeight : defaultStackViewHeightConstraint
    }

    func configureManageInsightButton() {

        guard let statSection,
            StatSection.allInsights.contains(statSection)
        else {
            showManageInsightButton(false)
            return
        }

        showManageInsightButton()
        manageInsightImageView.image = Style.imageForGridiconType(.ellipsis, withTint: .darkGrey)
    }

    // MARK: - Button Action

    @objc func manageInsightButtonPressed(_ sender: UIButton) {
        guard let statSection else {
            DDLogDebug("manageInsightButtonPressed: unknown statSection.")
            return
        }

        siteStatsInsightsDelegate?.manageInsightSelected?(statSection, fromButton: sender)
    }

    func showManageInsightButton(_ show: Bool = true) {
        manageInsightImageView.isHidden = !show
        manageInsightButton.isHidden = !show
    }
}
