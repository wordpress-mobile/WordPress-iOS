import UIKit

class StatsRevampV2FeatureIntroduction: FeatureIntroductionViewController {

    var presenter: StatsRevampV2IntroductionPresenter?

    init() {
        let featureDescriptionView = StatsRevampV2FeatureDescriptionView.loadFromNib()
        featureDescriptionView.translatesAutoresizingMaskIntoConstraints = false

        let headerImage = UIImage(named: HeaderStyle.imageName)?.withTintColor(.clear)

        super.init(headerTitle: HeaderStrings.title, headerSubtitle: "", headerImage: headerImage, featureDescriptionView: featureDescriptionView, primaryButtonTitle: ButtonStrings.showMe, secondaryButtonTitle: ButtonStrings.remindMe)

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

extension StatsRevampV2FeatureIntroduction: FeatureIntroductionDelegate {
    func primaryActionSelected() {
        presenter?.primaryButtonSelected()
    }

    func secondaryActionSelected() {
        presenter?.secondaryButtonSelected()
    }
}

private extension StatsRevampV2FeatureIntroduction {

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
        static let showMe = NSLocalizedString("Try it now", comment: "Button title to take user to the new Stats Insights screen.")
        static let remindMe = NSLocalizedString("Remind me later", comment: "Button title dismiss the Stats Insights feature announcement screen.")
    }

    enum HeaderStrings {
        static let title = NSLocalizedString("Insights update", comment: "Title displayed on the feature introduction view that announces the updated Stats Insight screen.")
    }

    enum HeaderStyle {
        static let imageName = "icon-lightbulb-outline"
        static let startGradientColor: UIColor = .warning(.shade30)
        static let endGradientColor: UIColor = .accent(.shade40)
    }
}
