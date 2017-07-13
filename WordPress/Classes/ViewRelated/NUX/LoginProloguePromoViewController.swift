import UIKit
import Lottie

class LoginProloguePromoViewController: UIViewController {
    @IBOutlet var stackView: UIStackView?
    @IBOutlet var headingLabel: UILabel?
    @IBOutlet var animationHolder: UIView?
    @IBInspectable var pageNum: Int = 0
    fileprivate var animationView: LOTAnimationView?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear
        headingLabel?.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: UIFontWeightBold)
        headingLabel?.text = headlineText()
        headingLabel?.sizeToFit()

        guard let holder = animationHolder,
            let animation = Lottie.LOTAnimationView(name: animationKey()) else {
                return
        }

        stackView?.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        stackView?.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView?.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.85).isActive = true

        animation.translatesAutoresizingMaskIntoConstraints = false
        animation.contentMode = .scaleAspectFit
        holder.addSubview(animation)

        animation.leadingAnchor.constraint(equalTo: holder.leadingAnchor).isActive = true
        animation.trailingAnchor.constraint(equalTo: holder.trailingAnchor).isActive = true
        animation.topAnchor.constraint(equalTo: holder.topAnchor).isActive = true
        animation.bottomAnchor.constraint(equalTo: holder.bottomAnchor).isActive = true
        animationView = animation
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        animationView?.loopAnimation = true
        animationView?.play()
    }

    private func animationKey() -> String {
        switch pageNum {
        case 1:
            return "post"
        case 2:
            return "stats"
        case 3:
            return "reader"
        case 4:
            return "notifications"
        case 5:
            fallthrough
        default:
            return "jetpack"
        }
    }

    private func headlineText() -> String {
        switch pageNum {
        case 1:
            return NSLocalizedString("Publish from the park. Blog from the bus. Comment from the café. WordPress goes where you do.", comment: "shown in promotional screens during first launch")
        case 2:
            return NSLocalizedString("Watch readers from around the world read and interact with your site — in real time.", comment: "shown in promotional screens during first launch")
        case 3:
            return NSLocalizedString("Catch up with your favorite sites and join the conversation anywhere, any time.", comment: "shown in promotional screens during first launch")
        case 4:
            return NSLocalizedString("Your notifications travel with you — see comments and likes as they happen.", comment: "shown in promotional screens during first launch")
        case 5:
            fallthrough
        default:
            return NSLocalizedString("Manage your Jetpack-powered site on the go — you‘ve got WordPress in your pocket.", comment: "shown in promotional screens during first launch")
        }
    }
}
