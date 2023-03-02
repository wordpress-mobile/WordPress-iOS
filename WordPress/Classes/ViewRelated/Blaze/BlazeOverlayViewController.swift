import UIKit

final class BlazeOverlayViewController: UIViewController {

    // MARK: - Subviews

    private lazy var closeButtonItem: UIBarButtonItem = {
        let closeButton = CircularImageButton()

        let fontForSystemImage = UIFont.systemFont(ofSize: Metrics.closeButtonSize)
        let configuration = UIImage.SymbolConfiguration(font: fontForSystemImage)
        let closeButtonImage = UIImage(systemName: Constants.closeButtonSystemName, withConfiguration: configuration)

        closeButton.setImage(closeButtonImage, for: .normal)
        closeButton.tintColor = UIColor(light: .systemGray6, dark: .systemGray5)
        closeButton.setImageBackgroundColor(UIColor(light: .black, dark: .white))

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: Metrics.closeButtonSize),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor)
        ])

        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        return UIBarButtonItem(customView: closeButton)
    }()

    private lazy var stackView: UIStackView = {
        let subviews = [
            imageView,
            titleLabel,
            descriptionLabel,
            footerStackView
        ]
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.stackViewSpacing
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "flame-circle"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Title"
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .bold)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .text
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Description"
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        return label
    }()

    private lazy var footerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [blazeButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.stackViewSpacing
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        return stackView
    }()

    private lazy var blazeButton: UIButton = {
        let button = FancyButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Blaze", for: .normal)
        button.addTarget(self, action: #selector(blazeButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Properties

    private let source: BlazeSource
    private let blog: Blog
    private let post: AbstractPost?

    // MARK: - Initializers

    init(source: BlazeSource, blog: Blog, post: AbstractPost? = nil) {
        self.source = source
        self.blog = blog
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        // This VC is designed to be initialized programmatically.
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupView()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = closeButtonItem

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .basicBackground
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationItem.compactScrollEdgeAppearance = appearance
        }
    }

    private func setupView() {
        view.backgroundColor = .basicBackground
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -Metrics.margin),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: Metrics.margin),
            view.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -Metrics.margin),
            blazeButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            blazeButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
    }

    // MARK: - Button Action

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func blazeButtonTapped() {
        guard let post else {
            BlazeWebViewCoordinator.presentBlazeFlow(in: self, source: source, blog: blog)
            return
        }

        BlazeWebViewCoordinator.presentBlazeFlow(in: self, source: source, blog: blog, postID: post.postID)
    }
}

extension BlazeOverlayViewController {

    private enum Metrics {
        static let margin: CGFloat = 20.0
        static let stackViewSpacing: CGFloat = 30.0
        static let closeButtonSize: CGFloat = 30.0
    }

    enum Constants {
        static let closeButtonSystemName = "xmark.circle.fill"
    }

}
