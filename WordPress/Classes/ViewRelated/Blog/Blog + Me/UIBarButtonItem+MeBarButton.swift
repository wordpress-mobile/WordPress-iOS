import Gridicons
import UIKit


/// Add a UIBarButtonItem to the navigation bar that  presents the Me scene.
extension BlogDetailsViewController {
    @objc
    private func presentHandler() {
        meScenePresenter.present(on: self, animated: true, completion: nil)
    }

    @objc
    func addMeButtonToNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(email: blog.account?.email,
                                                            target: self,
                                                            action: #selector(presentHandler))
    }
}

extension BlogListViewController {
    @objc
    private func presentHandler() {
        meScenePresenter.present(on: self, animated: true, completion: nil)
    }

    @objc
    func addMeButtonToNavigationBar(with email: String) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(email: email,
                                                            target: self,
                                                            action: #selector(presentHandler))
    }
}


/// methods to set the gravatar image on the me button
private extension UIBarButtonItem {
    /// gravatar configuration parameters
    struct GravatarConfiguration {
        static let radius: CGFloat = 24.0
        static let fallBackImage = Gridicon.iconOfType(.userCircle)
    }

    /// Assign the gravatar CircularImageView to the customView property and attach the passed target/action.
    /// If email is nil, fall back to the gravatar icon. Adds `Me` accessibility traits to the button
    convenience init(email: String?, style: UIBarButtonItem.Style = .plain, target: Any?, action: Selector?) {
        guard let email = email else {
            self.init(image: GravatarConfiguration.fallBackImage,
                      style: style,
                      target: target,
                      action: action)
            makeMeButtonAccessible()
            return
        }
        self.init()
        makeMeButtonAccessible()

        customView = makeGravatarView(with: email)
        addTapToCustomView(target: target, action: action)
    }

    /// Create the gravatar CircluarImageView with a fade animation on tap.
    func makeGravatarView(with email: String) -> CircularImageView {
        let gravatarImageView = CircularImageView()
        gravatarImageView.isUserInteractionEnabled = true
        gravatarImageView.animatesTouch = true

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


/// Accessibility
private extension UIBarButtonItem {
    /// Adds accessibility traits for the `Me` bar button item
    func makeMeButtonAccessible() {
        accessibilityLabel = NSLocalizedString("Me", comment: "Accessibility label for the Me button in My Site.")
        accessibilityHint = NSLocalizedString("Open the Me Section", comment: "Accessibility hint the Me button in My Site.")
        accessibilityIdentifier = "meBarButton"
        accessibilityTraits = UIAccessibilityTraits.button
        isAccessibilityElement = true
    }
}
