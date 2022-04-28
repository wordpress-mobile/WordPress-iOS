import UIKit

@objc protocol FeatureIntroductionDelegate: AnyObject {
    func primaryActionSelected()
    @objc optional func secondaryActionSelected()
}

// TODO: add description

class FeatureIntroductionViewController: CollapsableHeaderViewController {

    // MARK: - Properties

    private let scrollView: UIScrollView
    private let featureDescriptionView: UIView

    // View added to scrollView that contains specific Feature Introduction content.
    private lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(featureDescriptionView)
        contentView.pinSubviewToAllEdges(featureDescriptionView)
        return contentView
    }()

    weak var featureIntroductionDelegate: FeatureIntroductionDelegate?

    // MARK: - Init

    init(headerTitle: String,
         headerSubtitle: String,
         headerImage: UIImage? = nil,
         featureDescriptionView: UIView,
         primaryButtonTitle: String,
         secondaryButtonTitle: String? = nil) {

        self.featureDescriptionView = featureDescriptionView

        scrollView = {
            let scrollView = UIScrollView()
            scrollView.showsVerticalScrollIndicator = false
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            return scrollView
        }()

        super.init(
            scrollableView: scrollView,
            mainTitle: headerTitle,
            headerImage: headerImage,
            prompt: headerSubtitle,
            primaryActionTitle: primaryButtonTitle,
            secondaryActionTitle: secondaryButtonTitle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureVerticalButtonView()
    }

    // MARK: - Button Actions

    override func primaryActionSelected(_ sender: Any) {
        featureIntroductionDelegate?.primaryActionSelected()
    }

    override func secondaryActionSelected(_ sender: Any) {
        featureIntroductionDelegate?.secondaryActionSelected?()
    }

    @IBAction func closeButtonTapped() {
        dismiss(animated: true)
    }

}

private extension FeatureIntroductionViewController {

    func configureView() {
        navigationItem.rightBarButtonItem = CollapsableHeaderViewController.closeButton(target: self, action: #selector(closeButtonTapped))
        scrollView.addSubview(contentView)
        hideHeaderVisualEffects()

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

}
