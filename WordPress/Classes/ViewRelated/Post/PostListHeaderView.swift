import UIKit

final class PostListHeaderView: UIView {

    // MARK: - Views

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()

    private let dateLabel = UILabel()
    private let authorLabel = UILabel()
    private let ellipsisButton = UIButton(type: .custom)

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func configure(with viewModel: PostListItemViewModel) {
        authorLabel.text = viewModel.author
        dateLabel.text = viewModel.date
    }

    // MARK: - Setup

    private func setupView() {
        let dotLabel = UILabel()
        dotLabel.text = "\u{2022}"

        let labels = [
            dateLabel,
            dotLabel,
            authorLabel
        ]

        labels.enumerated().forEach { (index, label) in
            label.translatesAutoresizingMaskIntoConstraints = false
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 1
            label.font = WPStyleGuide.fontForTextStyle(.footnote, fontWeight: .regular)
            label.textColor = .textSubtle

            if index < labels.count - 1 {
                label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            }
        }

        let labelsStackView = UIStackView(arrangedSubviews: labels)
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.spacing = 2

        ellipsisButton.translatesAutoresizingMaskIntoConstraints = false
        ellipsisButton.setImage(UIImage(named: "more-horizontal-mobile"), for: .normal)
        ellipsisButton.tintColor = .listIcon

        NSLayoutConstraint.activate([
            ellipsisButton.widthAnchor.constraint(equalToConstant: 24)
        ])

        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubviews([
            labelsStackView,
            ellipsisButton
        ])
        mainStackView.spacing = 16

        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)
    }
}
