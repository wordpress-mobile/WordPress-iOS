import Lottie
import UIKit

class JetpackOverlayView: UIView {

    private var buttonAction: (() -> Void)?

    private var dismissButtonTintColor: UIColor {
        UIColor(light: .muriel(color: .gray, .shade5),
                dark: .muriel(color: .jetpackGreen, .shade90))
    }

    private var dismissButtonImage: UIImage {
        let fontForSystemImage = UIFont.systemFont(ofSize: Metrics.dismissButtonSize)
        let configuration = UIImage.SymbolConfiguration(font: fontForSystemImage)

        // fallback to the gridicon if for any reason the system image fails to render
        return UIImage(systemName: Graphics.dismissButtonSystemName, withConfiguration: configuration) ??
        UIImage.gridicon(.crossCircle, size: CGSize(width: Metrics.dismissButtonSize, height: Metrics.dismissButtonSize))
    }

    private lazy var dismissButton: CircularImageButton = {
        let button = CircularImageButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(dismissButtonImage, for: .normal)
        button.tintColor = dismissButtonTintColor
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [animationContainerView, titleLabel, descriptionLabel, getJetpackButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        return stackView
    }()

    private lazy var animationContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var animationView: AnimationView = {
        let animationView = AnimationView(name: Graphics.wpJetpackLogoAnimation)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        return animationView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = Metrics.minimumScaleFactor
        label.font = Metrics.titleFont
        label.numberOfLines = Metrics.titleLabelNumberOfLines
        label.textAlignment = .natural
        label.text = TextContent.title
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = Metrics.minimumScaleFactor
        label.font = Metrics.descriptionFont
        label.numberOfLines = Metrics.descriptionLabelNumberOfLines
        label.textAlignment = .natural
        label.text = TextContent.description
        return label
    }()

    private lazy var getJetpackButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .muriel(color: .jetpackGreen, .shade40)
        button.setTitle(TextContent.buttonTitle, for: .normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.layer.cornerRadius = Metrics.tryJetpackButtonCornerRadius
        button.layer.cornerCurve = .continuous
        return button
    }()

    @objc private func didTapButton() {
        buttonAction?()
    }

    @objc private func dismissTapped() {
        guard let presentingViewController = next as? UIViewController else {
            return
        }
        presentingViewController.dismiss(animated: true)
    }

    private func setup() {
        backgroundColor = UIColor(light: .muriel(color: .jetpackGreen, .shade0),
                                  dark: .muriel(color: .jetpackGreen, .shade100))
        addSubview(dismissButton)
        addSubview(stackView)
        stackView.setCustomSpacing(Metrics.imageToTitleSpacing, after: animationContainerView)
        stackView.setCustomSpacing(Metrics.titleToDescriptionSpacing, after: titleLabel)
        stackView.setCustomSpacing(Metrics.descriptionToButtonSpacing, after: descriptionLabel)
        animationContainerView.addSubview(animationView)
        getJetpackButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        configureConstraints()
        dismissButton.setImageBackgroundColor(UIColor(light: .black, dark: .white))
        animationView.play()
    }

    init(buttonAction: (() -> Void)? = nil) {
        self.buttonAction = buttonAction
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureConstraints() {
        animationContainerView.pinSubviewToAllEdges(animationView)


        let stackViewTrailingConstraint = stackView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                                              constant: -Metrics.edgeMargins.right)
        stackViewTrailingConstraint.priority = Metrics.veryHighPriority
        let stackViewBottomConstraint = stackView.bottomAnchor.constraint(lessThanOrEqualTo: safeBottomAnchor,
                                                                          constant: -Metrics.edgeMargins.bottom)
        stackViewBottomConstraint.priority = Metrics.veryHighPriority

        NSLayoutConstraint.activate([
            dismissButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.dismissButtonPadding),
            dismissButton.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.dismissButtonPadding),
            dismissButton.heightAnchor.constraint(equalToConstant: Metrics.dismissButtonSize),
            dismissButton.widthAnchor.constraint(equalToConstant: Metrics.dismissButtonSize),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.edgeMargins.left),
            stackViewTrailingConstraint,
            stackView.topAnchor.constraint(equalTo: dismissButton.bottomAnchor),
            stackViewBottomConstraint,

            getJetpackButton.heightAnchor.constraint(equalToConstant: Metrics.tryJetpackButtonHeight),
            getJetpackButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
    }
}

// MARK: Appearance
private extension JetpackOverlayView {

    enum Graphics {
        static let wpJetpackLogoAnimation = "JetpackWordPressLogoAnimation_left"
        static let dismissButtonSystemName = "xmark.circle.fill"
    }

    enum Metrics {
        // stack view
        static let imageToTitleSpacing: CGFloat = 24
        static let titleToDescriptionSpacing: CGFloat = 20
        static let descriptionToButtonSpacing: CGFloat = 40
        static let edgeMargins = UIEdgeInsets(top: 46, left: 30, bottom: 20, right: 30)
        // dismiss button
        static let dismissButtonPadding: CGFloat = 20
        static let dismissButtonSize: CGFloat = 30
        // labels
        static let maximumFontSize: CGFloat = 32
        static let minimumScaleFactor: CGFloat = 0.6

        static let titleLabelNumberOfLines = 2

        static let descriptionLabelNumberOfLines = 0

        static var titleFont: UIFont {
            let weightTrait = [UIFontDescriptor.TraitKey.weight: UIFont.Weight.bold]
            let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title1).addingAttributes([.traits: weightTrait])
            let font = UIFont(descriptor: fontDescriptor, size: min(fontDescriptor.pointSize, maximumFontSize))
            return UIFontMetrics.default.scaledFont(for: font, maximumPointSize: maximumFontSize)
        }

        static var descriptionFont: UIFont {
            let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            let font = UIFont(descriptor: fontDescriptor, size: min(fontDescriptor.pointSize, maximumFontSize))
            return UIFontMetrics.default.scaledFont(for: font, maximumPointSize: maximumFontSize)
        }
        // "Try Jetpack" button
        static let tryJetpackButtonHeight: CGFloat = 44
        static let tryJetpackButtonCornerRadius: CGFloat = 6
        // constraints
        static let veryHighPriority = UILayoutPriority(rawValue: 999)
    }

    enum TextContent {
        static let title = NSLocalizedString("jetpack.branding.overlay.title",
                                             value: "WordPress is better with Jetpack",
                                             comment: "Title of the Jetpack powered overlay.")

        static let description = NSLocalizedString("jetpack.branding.overlay.description",
                                                   value: "The new Jetpack app has Stats, Reader, Notifications, and more that make your WordPress better.",
                                                   comment: "Description of the Jetpack powered overlay.")

        static let buttonTitle = NSLocalizedString("jetpack.branding.overlay.button.title",
                                                   value: "Try the new Jetpack app",
                                                   comment: "Button title of the Jetpack powered overlay.")
    }
}
