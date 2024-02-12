
class EmptyFilterView: UIView {

    private let viewModel: EmptyFilterViewModel

    private lazy var stackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.spacing = 16.0
        let subviews = {
            viewModel.filterType == .blog ?
            [titleLabel, bodyLabel, searchButton] :
            [titleLabel, bodyLabel, suggestedButton, searchButton]
        }()
        $0.addArrangedSubviews(subviews)
        $0.setCustomSpacing(8.0, after: titleLabel)
        $0.setCustomSpacing(32.0, after: bodyLabel)
        return $0
    }(UIStackView())

    private lazy var titleLabel: UILabel = {
        $0.text = viewModel.title
        $0.textAlignment = .center
        $0.font = .preferredFont(forTextStyle: .title3).semibold()
        return $0
    }(UILabel())

    private lazy var bodyLabel: UILabel = {
        $0.text = viewModel.body
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.font = .preferredFont(forTextStyle: .callout)
        $0.textColor = .secondaryLabel
        return $0
    }(UILabel())

    private var buttonConfig: UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 12.0, leading: 0.0, bottom: 12.0, trailing: 0.0)
        config.titleTextAttributesTransformer = .transformer(with: .preferredFont(forTextStyle: .body).semibold())
        return config
    }

    private lazy var suggestedButton: UIButton = {
        $0.configuration = buttonConfig
        $0.setTitle(viewModel.suggestedButton, for: .normal)
        $0.setTitleColor(.systemBackground, for: .normal)
        $0.setTitleColor(.systemBackground.withAlphaComponent(0.7), for: .highlighted)
        $0.backgroundColor = .text
        $0.layer.cornerRadius = 5.0
        $0.addTarget(self, action: #selector(suggestedButtonTapped), for: .touchUpInside)
        return $0
    }(UIButton())

    private lazy var searchButton: UIButton = {
        $0.configuration = buttonConfig
        $0.setTitle(viewModel.searchButton, for: .normal)
        $0.setTitleColor(.text, for: .normal)
        $0.setTitleColor(.text.withAlphaComponent(0.7), for: .highlighted)
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 5.0
        $0.layer.borderWidth = 1.0
        $0.layer.borderColor = UIColor.tertiaryLabel.cgColor
        $0.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        return $0
    }(UIButton())

    init(viewModel: EmptyFilterViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: safeTopAnchor, constant: 12.0),
            stackView.leadingAnchor.constraint(equalTo: safeLeadingAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: safeTrailingAnchor, constant: -16.0),
        ])
    }

    @objc private func suggestedButtonTapped() {
        viewModel.suggestedButtonTap?()
    }

    @objc private func searchButtonTapped() {
        viewModel.searchButtonTap?()
    }

}
