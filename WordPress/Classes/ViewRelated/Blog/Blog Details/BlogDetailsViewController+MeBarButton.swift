import Gridicons
import UIKit


/// Add a UIBarButtonItem to the navigation bar that  presents the Me scene.
extension BlogDetailsViewController {

    private func makeMeBarButton() -> UIBarButtonItem {
        return UIBarButtonItem(email: blog.account?.email,
                               target: self,
                               action: #selector(presentHandler))
    }

    @objc
    private func presentHandler() {
        scenePresenter.present(on: self)
    }

    @objc
    func addMeButtonToNavigationBar() {
        navigationItem.rightBarButtonItem = makeMeBarButton()
    }
}


/// methods to set the gravatar image on the me button
private extension UIBarButtonItem {
    /// gravatar configuration parameters
    struct GravatarConfiguration {
        static let radius: CGFloat = 24.0
        static let startAlpha: CGFloat = 0.5
        static let endAlpha: CGFloat = 1.0
        static let aimationDuration: TimeInterval = 0.5
        static let fallBackImage = Gridicon.iconOfType(.userCircle)
    }

    /// Assign the gravatar CircularImageView to the customView property and attach the passed target/action.
    /// If email is nil, fall back to the gravatar icon.
    convenience init(email: String?, style: UIBarButtonItem.Style = .plain, target: Any?, action: Selector?) {
        guard let email = email else {
            self.init(image: GravatarConfiguration.fallBackImage,
                      style: style,
                      target: target,
                      action: action)
            return
        }
        self.init()

        customView = makeGravatarView(with: email)
        addTapToCustomView(target: target, action: action)
    }

    /// Create the gravatar CircluarImageView with a fade animation on tap.
    func makeGravatarView(with email: String) -> CircularImageView {
        let gravatarImageView = CircularImageView()
        gravatarImageView.isUserInteractionEnabled = true

        gravatarImageView.tapAnimation = { imageView in
            imageView.alpha = GravatarConfiguration.startAlpha
            UIView.animate(withDuration: GravatarConfiguration.aimationDuration) {
                imageView.alpha = GravatarConfiguration.endAlpha
            }
        }

        gravatarImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: gravatarImageView,
                           attribute: .width,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1,
                           constant: GravatarConfiguration.radius)
            .isActive = true

        NSLayoutConstraint(item: gravatarImageView,
                           attribute: .height,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1,
                           constant: GravatarConfiguration.radius)
            .isActive = true

        gravatarImageView.contentMode = .scaleAspectFit

        gravatarImageView.downloadGravatarWithEmail(email, placeholderImage: GravatarConfiguration.fallBackImage)
        return gravatarImageView
    }

    /// adds a 'tap' action to customView
    func addTapToCustomView(target: Any?, action: Selector?) {
        customView?.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: target, action: action)
        customView?.addGestureRecognizer(tapRecognizer)
    }
}
