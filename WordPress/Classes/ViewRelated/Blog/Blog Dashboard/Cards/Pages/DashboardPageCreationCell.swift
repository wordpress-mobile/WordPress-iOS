import UIKit

class DashboardPageCreationCell: UITableViewCell, Reusable {

    // MARK: Views

    lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.addArrangedSubviews([descriptionLabel])
        return stackView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .bold)
        return label
    }()

    // MARK: Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    // MARK: Public Functions

    func configure(expanded: Bool, hasPages: Bool) {
        descriptionLabel.text = "Hello World"
    }

    // MARK: Helpers

    private func commonInit() {
        setupViews()
        applyStyle()
    }

    private func applyStyle() {
        backgroundColor = .clear
    }

    private func setupViews() {
        contentView.addSubview(mainStackView)
        contentView.pinSubviewToAllEdges(mainStackView)
    }
}

private extension DashboardPageCreationCell {
    enum Metrics {
    }

    enum Colors {
    }
}
