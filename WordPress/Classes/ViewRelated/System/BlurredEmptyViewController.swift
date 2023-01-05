import UIKit

/// An empty view controller that has a blurred background
/// The blurred background can be removed using `removeBlurView()`
class BlurredEmptyViewController: UIViewController {

    // MARK: Lazy Private Variables

    private lazy var visualEffectView: UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        return visualEffectView
    }()

    // MARK: Public Functions

    func removeBlurView() {
        visualEffectView.removeFromSuperview()
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        view.addSubview(visualEffectView)
        view.pinSubviewToAllEdges(visualEffectView)
    }
}
