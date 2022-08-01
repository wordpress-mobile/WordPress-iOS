import UIKit

class JetpackOverlayView: UIView {

    private var buttonAction: (() -> Void)?

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel, descriptionLabel, getJetpackButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()

    // TODO: This will need to be replaced with the animated images
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: Images.jetpackLogo))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .bold)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.text = TextContent.title
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = TextContent.description
        return label
    }()

    private lazy var getJetpackButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .muriel(color: .jetpackGreen, .shade40)
        button.setTitle(TextContent.buttonTitle, for: .normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.layer.cornerRadius = Metrics.buttonCornerRadius
        button.layer.cornerCurve = .continuous
        return button
    }()

    @objc private func didTapButton() {
        buttonAction?()
    }

    private func setup(buttonAction: (() -> Void)?) {
        backgroundColor = UIColor(light: .muriel(color: .jetpackGreen, .shade0),
                                  dark: .muriel(color: .jetpackGreen, .shade100))
        addSubview(stackView)
        stackView.setCustomSpacing(Metrics.imageToTitleSpacing, after: imageView)
        stackView.setCustomSpacing(Metrics.descriptionToButtonSpacing, after: descriptionLabel)
        getJetpackButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        configureConstraints()
    }

    init(buttonAction: (() -> Void)? = nil) {
        super.init(frame: .zero)
        setup(buttonAction: buttonAction)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.edgeMargins.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.edgeMargins.right),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.edgeMargins.top),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: safeBottomAnchor, constant: -Metrics.edgeMargins.bottom),

            getJetpackButton.heightAnchor.constraint(equalToConstant: Metrics.getJetpackButtonHeight),
            getJetpackButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
    }
}


// MARK: Appearance
private extension JetpackOverlayView {

    enum Images {
        // TODO: this is temporary and will be replaced with the animation
        static let jetpackLogo = "jetpack-install-logo"
    }

    enum Metrics {
        static let imageToTitleSpacing: CGFloat = 24
        static let descriptionToButtonSpacing: CGFloat = 40
        static let edgeMargins = UIEdgeInsets(top: 46, left: 20, bottom: 20, right: 20)
        static let getJetpackButtonHeight: CGFloat = 44
        static let buttonCornerRadius: CGFloat = 6
    }

    enum TextContent {
        static let title = NSLocalizedString("jetpack.branding.overlay.title",
                                             value: "Jetpack powered",
                                             comment: "Title of the Jetpack powered overlay.")

        static let description = NSLocalizedString("jetpack.branding.overlay.description",
                                                   value: "Stats, Reader, Notifications, and other features are provided by Jetpack.",
                                                   comment: "Description of the Jetpack powered overlay.")

        static let buttonTitle = NSLocalizedString("jetpack.branding.overlay.button.title",
                                                   value: "Get the new Jetpack app",
                                                   comment: "Button title of the Jetpack powered overlay.")
    }
}
