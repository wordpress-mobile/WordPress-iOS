import UIKit

/// This displays a Feature Introduction specifically for Blogging Prompts.

class BloggingPromptsFeatureIntroduction: FeatureIntroductionViewController {

   var presenter: BloggingPromptsIntroductionPresenter?

    private var interactionType: BloggingPromptsFeatureIntroduction.InteractionType

    enum InteractionType {
        // Two buttons are displayed, both perform an action.
        case actionable
        // One button is displayed, which only dismisses the view.
        case informational

        var primaryButtonTitle: String {
            switch self {
            case .actionable:
                return ButtonStrings.tryIt
            case .informational:
                return ButtonStrings.gotIt
            }
        }

        var secondaryButtonTitle: String? {
            switch self {
            case .actionable:
                return ButtonStrings.remindMe
            default:
                return nil
            }
        }
    }

    class func navigationController(interactionType: BloggingPromptsFeatureIntroduction.InteractionType) -> UINavigationController {
        let controller = BloggingPromptsFeatureIntroduction(interactionType: interactionType)
        let navController = UINavigationController(rootViewController: controller)
        return navController
    }

    init(interactionType: BloggingPromptsFeatureIntroduction.InteractionType) {

        let featureDescriptionView: BloggingPromptsFeatureDescriptionView = {
            let featureDescriptionView = BloggingPromptsFeatureDescriptionView.loadFromNib()
             featureDescriptionView.translatesAutoresizingMaskIntoConstraints = false
            return featureDescriptionView
        }()

        let headerImage = UIImage(named: HeaderStyle.imageName)?.withTintColor(.clear)

        self.interactionType = interactionType

        super.init(headerTitle: HeaderStrings.title,
                   headerSubtitle: HeaderStrings.subtitle,
                   headerImage: headerImage,
                   featureDescriptionView: featureDescriptionView,
                   primaryButtonTitle: interactionType.primaryButtonTitle,
                   secondaryButtonTitle: interactionType.secondaryButtonTitle)

        featureIntroductionDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the gradient after the image has been added to the view so the gradient is the correct size.
        addHeaderImageGradient()
    }

    override func closeButtonTapped() {
        WPAnalytics.track(.promptsIntroductionModalDismissed)
        super.closeButtonTapped()
    }

}

extension BloggingPromptsFeatureIntroduction: FeatureIntroductionDelegate {

    func primaryActionSelected() {
        guard interactionType == .actionable else {
            WPAnalytics.track(.promptsIntroductionModalGotIt)
            super.closeButtonTapped()
            return
        }

        WPAnalytics.track(.promptsIntroductionModalTryItNow)
        presenter?.primaryButtonSelected()
    }

    func secondaryActionSelected() {
        guard interactionType == .actionable else {
            return
        }

        WPAnalytics.track(.promptsIntroductionModalRemindMe)
        presenter?.secondaryButtonSelected()
    }

}

private extension BloggingPromptsFeatureIntroduction {

    func addHeaderImageGradient() {
        // Based on https://stackoverflow.com/a/54096829
        let gradient = CAGradientLayer()

        gradient.colors = [
            HeaderStyle.startGradientColor.cgColor,
            HeaderStyle.endGradientColor.cgColor
        ]

        // Create a gradient from top to bottom.
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradient.frame = headerImageView.bounds

        // Add a mask to the gradient so the colors only apply to the image (and not the imageView).
        let mask = CALayer()
        mask.contents = headerImageView.image?.cgImage
        mask.frame = gradient.bounds
        gradient.mask = mask

        // Add the gradient as a sublayer to the imageView's layer.
        headerImageView.layer.addSublayer(gradient)
    }

    enum ButtonStrings {
        static let tryIt = NSLocalizedString("Try it now", comment: "Button title on the blogging prompt's feature introduction view to answer a prompt.")
        static let gotIt = NSLocalizedString("Got it", comment: "Button title on the blogging prompt's feature introduction view to dismiss the view.")
        static let remindMe = NSLocalizedString("Remind me", comment: "Button title on the blogging prompt's feature introduction view to set a reminder.")
    }

    enum HeaderStrings {
        static let title: String = NSLocalizedString("Introducing Prompts", comment: "Title displayed on the feature introduction view.")
        static let subtitle: String = NSLocalizedString("The best way to become a better writer is to build a writing habit and share with others - that’s where Prompts come in!", comment: "Subtitle displayed on the feature introduction view.")
    }

    enum HeaderStyle {
        static let imageName = "icon-lightbulb-outline"
        static let startGradientColor: UIColor = .warning(.shade30)
        static let endGradientColor: UIColor = .accent(.shade40)
    }

}
