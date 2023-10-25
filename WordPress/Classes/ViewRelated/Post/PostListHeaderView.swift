import UIKit

final class PostListHeaderView: UIView {

    // MARK: - Views

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var labelsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()

    private let dateLabel = UILabel()
    private let dotLabel = UILabel()
    private let authorLabel = UILabel()
    private let ellipsisButton = UIButton(type: .custom)

    // MARK: - Properties

    private var post: Post?
    private var viewModel: PostListItemViewModel?

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func configure(with viewModel: PostListItemViewModel, delegate: InteractivePostViewDelegate? = nil) {
        if let delegate {
            configureEllipsisButton(with: viewModel, delegate: delegate)
        }

        authorLabel.text = viewModel.author
        dateLabel.text = viewModel.date
        dateLabel.textColor = viewModel.post.status == .trash ? .systemRed : .secondaryLabel
    }

    private func configureEllipsisButton(with viewModel: PostListItemViewModel, delegate: InteractivePostViewDelegate) {
        let menuHelper = PostMenuHelper(statusViewModel: viewModel.statusViewModel)
        ellipsisButton.showsMenuAsPrimaryAction = true
        ellipsisButton.menu = menuHelper.makeMenu(presentingView: ellipsisButton, delegate: delegate)
    }

    // MARK: - Setup

    private func setupView() {
        setupLabelStackView()
        setupEllipsisButton()

        dateLabel.setContentCompressionResistancePriority(.init(rawValue: 800), for: .horizontal)

        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubviews([
            labelsStackView,
            ellipsisButton
        ])
        mainStackView.spacing = 16

        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView)
    }

    private func setupLabelStackView() {
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

        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.addArrangedSubviews(labels)
        labelsStackView.spacing = 2
    }

    private func setupEllipsisButton() {
        ellipsisButton.translatesAutoresizingMaskIntoConstraints = false
        ellipsisButton.setImage(UIImage(named: "more-horizontal-mobile"), for: .normal)
        ellipsisButton.tintColor = .listIcon
        ellipsisButton.addTarget(self, action: #selector(ellipsisButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            ellipsisButton.widthAnchor.constraint(equalToConstant: 24)
        ])
    }

    @objc private func ellipsisButtonTapped() {
        // TODO
    }
}
