import Gridicons
import UIKit


/// Add a UIBarButtonItem to the navigation bar that  presents the Me scene.
extension BlogDetailsViewController {
    @objc
    func presentHandler() {
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
        static let radius: CGFloat = 32
        static let tappableWidth: CGFloat = 44
        static let fallBackImage = UIImage.gridicon(.user)
    }

    /// Assign the gravatar CircularImageView to the customView property and attach the passed target/action.
    convenience init(email: String?, style: UIBarButtonItem.Style = .plain, target: Any?, action: Selector?) {
        self.init()
        makeMeButtonAccessible()
        customView = makeGravatarTappableView(with: email, target: target, action: action)
    }

    /// Create the gravatar CircluarImageView with a fade animation on tap.
    /// If no valid email is provided, fall back to the circled user icon
    func makeGravatarTappableView(with email: String?, target: Any?, action: Selector?) -> UIView {
        let gravatarImageView = GravatarButtonView(tappableWidth: GravatarConfiguration.tappableWidth)

        gravatarImageView.isUserInteractionEnabled = true
        setSize(of: gravatarImageView, size: GravatarConfiguration.radius)
        gravatarImageView.contentMode = .scaleAspectFit
        gravatarImageView.setBorder()

        if let email = email {
            gravatarImageView.downloadGravatarWithEmail(email, placeholderImage: GravatarConfiguration.fallBackImage)
        } else {
            gravatarImageView.image = GravatarConfiguration.fallBackImage
        }

        let tapRecognizer = UITapGestureRecognizer(target: target, action: action)
        gravatarImageView.addGestureRecognizer(tapRecognizer)

        return embedInView(gravatarImageView)
    }

    /// embeds a view in a transparent view, vertically centered and aligned to the right
    func embedInView(_ imageView: UIImageView) -> UIView {
        let view = UIView()
        setSize(of: view, size: GravatarConfiguration.tappableWidth)
        view.addSubview(imageView)
        NSLayoutConstraint(item: imageView,
                           attribute: .centerY,
                           relatedBy: .equal,
                           toItem: view,
                           attribute: .centerY,
                           multiplier: 1,
                           constant: 0)
            .isActive = true

        NSLayoutConstraint(item: imageView,
                           attribute: .trailingMargin,
                       relatedBy: .equal,
                       toItem: view,
                       attribute: .trailingMargin,
                       multiplier: 1,
                       constant: 0)
        .isActive = true

        return view
    }

    /// constrains a squared UIImageView to a set size
    func setSize(of view: UIView, size: CGFloat) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: view,
                           attribute: .width,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1,
                           constant: size)
            .isActive = true

        NSLayoutConstraint(item: view,
                           attribute: .height,
                           relatedBy: .equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1,
                           constant: size)
            .isActive = true
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
