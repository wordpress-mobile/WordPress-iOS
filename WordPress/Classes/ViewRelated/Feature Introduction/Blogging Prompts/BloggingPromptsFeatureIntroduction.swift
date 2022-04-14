import UIKit

// TODO: add description

class BloggingPromptsFeatureIntroduction: FeatureIntroductionViewController {

    class func navigationController() -> UINavigationController {
        let controller = BloggingPromptsFeatureIntroduction()
        let navController = UINavigationController(rootViewController: controller)
        return navController
    }

    init() {
        let featureDescriptionView: BloggingPromptsFeatureDescriptionView = {
            let featureDescriptionView = BloggingPromptsFeatureDescriptionView.loadFromNib()
             featureDescriptionView.translatesAutoresizingMaskIntoConstraints = false
            return featureDescriptionView
        }()

        let headerImage = UIImage(named: HeaderStyle.imageName)?
            .withTintColor(.clear)

        super.init(headerTitle: Strings.headerTitle,
                   headerSubtitle: Strings.headerSubtitle,
                   headerImage: headerImage,
                   featureDescriptionView: featureDescriptionView,
                   primaryButtonTitle: Strings.primaryButtonTitle,
                   secondaryButtonTitle: Strings.secondaryButtonTitle)

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

}

extension BloggingPromptsFeatureIntroduction: FeatureIntroductionDelegate {

    func primaryActionSelected() {
        // TODO: show site selector/draft post
    }

    func secondaryActionSelected() {
        // TODO: show site selector/Blogging Reminders
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

    enum Strings {
        static let headerTitle: String = NSLocalizedString("Introducing Prompts", comment: "Title displayed on the feature introduction view.")
        static let headerSubtitle: String = NSLocalizedString("The best way to become a better writer is to build a writing habit and share with others - that’s where Prompts come in!", comment: "Subtitle displayed on the feature introduction view.")
        static let primaryButtonTitle: String = NSLocalizedString("Try it now", comment: "Primary button title on the feature introduction view.")
        static let secondaryButtonTitle: String = NSLocalizedString("Remind me", comment: "Secondary button title on the feature introduction view.")
    }

    enum HeaderStyle {
        static let imageName = "icon-lightbulb-outline"
        static let startGradientColor: UIColor = .warning(.shade30)
        static let endGradientColor: UIColor = .accent(.shade40)
    }

}
