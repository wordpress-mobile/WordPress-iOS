import UIKit
import WordPressUI

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

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false

        scrollView.addSubview(stackView)
        scrollView.pinSubviewToAllEdges(stackView)
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        return scrollView
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
        let imageView = UIImageView(image: UIImage(named: viewModel.iconName))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = viewModel.title
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.font = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .semibold)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .text
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = viewModel.bulletedDescription(font: WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular),
                                                             textColor: .textSubtle)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        return label
    }()

    private lazy var footerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [blazeButton])

        if let post {
            let previewView = BlazePostPreviewView(post: post)
            previewView.translatesAutoresizingMaskIntoConstraints = false
            stackView.insertArrangedSubview(previewView, at: 0)
        }

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Metrics.footerStackViewSpacing
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var blazeButton: UIButton = {
        let button = FancyButton()
        button.isPrimary = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.primaryNormalBackgroundColor = Colors.blazeButtonBackgroundColor
        button.setAttributedTitle(viewModel.buttonTitle, for: .normal)
        button.addTarget(self, action: #selector(blazeButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Properties

    private let source: BlazeSource
    private let blog: Blog
    private let post: AbstractPost?
    private let viewModel: BlazeOverlayViewModel

    // MARK: - Initializers

    init(source: BlazeSource, blog: Blog, post: AbstractPost? = nil) {
        self.source = source
        self.blog = blog
        self.post = post
        self.viewModel = BlazeOverlayViewModel(source: source, blog: blog, post: post)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        BlazeEventsTracker.trackOverlayDisplayed(for: source)
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = closeButtonItem

        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = Colors.backgroundColor
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
    }

    private func setupView() {
        view.backgroundColor = Colors.backgroundColor
        view.addSubview(scrollView)
        view.pinSubviewToAllEdges(scrollView, insets: Metrics.contentInsets)

        NSLayoutConstraint.activate([
            blazeButton.heightAnchor.constraint(equalToConstant: Metrics.blazeButtonHeight),
            blazeButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            blazeButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])

    }

    // MARK: - Button Action

    @objc private func closeButtonTapped() {
        BlazeEventsTracker.trackOverlayDismissed(for: source)
        dismiss(animated: true)
    }

    @objc private func blazeButtonTapped() {
        BlazeEventsTracker.trackOverlayButtonTapped(for: source)

        guard let post else {
            BlazeFlowCoordinator.presentBlazeWebFlow(in: self, source: source, blog: blog, delegate: self)
            return
        }

        BlazeFlowCoordinator.presentBlazeWebFlow(in: self, source: source, blog: blog, postID: post.postID, delegate: self)
    }
}

// MARK: - BlazeWebViewControllerDelegate

extension BlazeOverlayViewController: BlazeWebViewControllerDelegate {

    func dismissBlazeWebViewController(_ controller: BlazeWebViewController) {
        presentingViewController?.dismiss(animated: true)
    }
}

private extension BlazeOverlayViewController {

    enum Metrics {
        static let contentInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
        static let stackViewSpacing: CGFloat = 30.0
        static let footerStackViewSpacing: CGFloat = 10.0
        static let closeButtonSize: CGFloat = 30.0
        static let blazeButtonHeight: CGFloat = 54.0
    }

    enum Constants {
        static let closeButtonSystemName = "xmark.circle.fill"
    }

    enum Colors {
        static let blazeButtonBackgroundColor = UIColor(light: .black, dark: UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1))
        static let backgroundColor = UIColor(light: .systemBackground, dark: .black)
    }

}
