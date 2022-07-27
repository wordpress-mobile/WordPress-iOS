import UIKit

@objc protocol FeatureIntroductionDelegate: AnyObject {
    func primaryActionSelected()
    @objc optional func secondaryActionSelected()
    @objc optional func closeButtonWasTapped()
}

/// This is used to display a modal with information about a new feature.
/// The feature description is displayed via the provided featureDescriptionView,
/// which is presented in the scrollable area of the view.
/// A primary action button is always displayed.
/// A secondary action button is displayed if a secondaryButtonTitle is provided.

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

    // MARK: - Header View Configuration

    override var separatorStyle: SeparatorStyle {
        return .hidden
    }

    override var alwaysResetHeaderOnRotation: Bool {
        WPDeviceIdentification.isiPhone()
    }

    override var alwaysShowHeaderTitles: Bool {
        true
    }

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
        featureIntroductionDelegate?.closeButtonWasTapped?()
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
