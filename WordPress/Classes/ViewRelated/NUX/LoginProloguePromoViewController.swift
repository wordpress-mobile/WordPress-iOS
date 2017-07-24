import UIKit
import Lottie

class LoginProloguePromoViewController: UIViewController {
    fileprivate let type: PromoType
    fileprivate let stackView: UIStackView
    fileprivate let headingLabel: UILabel
    fileprivate let animationHolder: UIView
    fileprivate var animationView: LOTAnimationView

    fileprivate struct Constants {
        static let stackSpacing: CGFloat = 36.0
        static let stackHeightMultiplier: CGFloat = 0.87
        static let stackWidthMultiplier: CGFloat = 0.8
    }

    enum PromoType: String {
        case post
        case stats
        case reader
        case notifications
        case jetpack

        func animationKey() -> String {
            return self.rawValue
        }
    }

    init(as promoType: PromoType) {
        type = promoType
        stackView = UIStackView()
        headingLabel = UILabel()
        animationHolder = UIView()
        guard let animation = Lottie.LOTAnimationView(name: type.animationKey()) else {
            fatalError("animation could not be created for promo screen \(promoType)")
        }
        animationView = animation

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear

        headingLabel.font = WPStyleGuide.mediumWeightFont(forStyle: .title3)
        headingLabel.textColor = headlineColor()
        headingLabel.text = headlineText()
        headingLabel.textAlignment = .center
        headingLabel.numberOfLines = 0
        headingLabel.sizeToFit()

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        animationView.animationProgress = 0.0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animationView.play()
    }


    // MARK: layout

    private func setupLayout() {
        view.addSubview(stackView)
        stackView.addArrangedSubview(headingLabel)
        stackView.addArrangedSubview(animationHolder)
        animationHolder.addSubview(animationView)

        stackView.axis = .vertical
        stackView.spacing = Constants.stackSpacing
        if self.traitCollection.horizontalSizeClass == .regular {
            stackView.alignment = .center
        } else {
            stackView.alignment = .fill
        }
        stackView.distribution = .fill

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: Constants.stackWidthMultiplier).isActive = true
        stackView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: Constants.stackHeightMultiplier).isActive = true

        headingLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 21.0).isActive = true
        headingLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 600.0).isActive = true
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        headingLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
        headingLabel.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)

        animationHolder.translatesAutoresizingMaskIntoConstraints = false
        animationHolder.widthAnchor.constraint(greaterThanOrEqualTo: animationHolder.heightAnchor, multiplier: 0.6667)
        animationHolder.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
        animationHolder.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)

        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.leadingAnchor.constraint(equalTo: animationHolder.leadingAnchor).isActive = true
        animationView.trailingAnchor.constraint(equalTo: animationHolder.trailingAnchor).isActive = true
        animationView.topAnchor.constraint(equalTo: animationHolder.topAnchor).isActive = true
        animationView.bottomAnchor.constraint(equalTo: animationHolder.bottomAnchor).isActive = true
    }


    // MARK: promo settings

    private func headlineColor() -> UIColor {
        switch type {
        case .post, .reader, .jetpack:
            return UIColor(hexString: "204E80")
        default:
            return UIColor.white
        }
    }

    private func headlineText() -> String {
        switch type {
        case .post:
            return NSLocalizedString("Publish from the park. Blog from the bus. Comment from the café. WordPress goes where you do.", comment: "shown in promotional screens during first launch")
        case .stats:
            return NSLocalizedString("Watch readers from around the world read and interact with your site — in real time.", comment: "shown in promotional screens during first launch")
        case .reader:
            return NSLocalizedString("Catch up with your favorite sites and join the conversation anywhere, any time.", comment: "shown in promotional screens during first launch")
        case .notifications:
            return NSLocalizedString("Your notifications travel with you — see comments and likes as they happen.", comment: "shown in promotional screens during first launch")
        case .jetpack:
            return NSLocalizedString("Manage your Jetpack-powered site on the go — you‘ve got WordPress in your pocket.", comment: "shown in promotional screens during first launch")
        }
    }
}
