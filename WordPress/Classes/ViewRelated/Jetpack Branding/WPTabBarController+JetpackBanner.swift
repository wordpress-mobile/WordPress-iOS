import UIKit

extension WPTabBarController {

    /// Adds a Jetpack powered banner on top of the main tab bar.
    @objc func addJetpackBanner() {

        guard AppConfiguration.isWordPress else {
            return
        }

        jetpackBannerView = UIView()
        jetpackBannerView.translatesAutoresizingMaskIntoConstraints = false


        jetpackBannerView.backgroundColor = Appearance.jetpackBackgroundColor

        view.insertSubview(jetpackBannerView, belowSubview: tabBar)

        let jetpackButton = makeJetpackButton()
        jetpackBannerView.addSubview(jetpackButton)

        NSLayoutConstraint.activate([
            jetpackBannerView.heightAnchor.constraint(equalToConstant: Appearance.jetpackBannerHeight),
            jetpackBannerView.bottomAnchor.constraint(equalTo: tabBar.topAnchor),
            jetpackBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            jetpackBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        jetpackBannerView.pinSubviewToAllEdges(jetpackButton)
        NotificationCenter.default.post(name: .jetpackBannerToggled, object: true)

    }

    private func makeJetpackButton() -> UIButton {
        let jetpackButton = UIButton()
        jetpackButton.translatesAutoresizingMaskIntoConstraints = false
        jetpackButton.setTitle(Appearance.jetpackBannerTitle, for: .normal)
        jetpackButton.tintColor = .muriel(color: .jetpackGreen, .shade40)
        jetpackButton.setTitleColor(UIColor(light: .black, dark: .white), for: .normal)
        jetpackButton.titleLabel?.font = Appearance.jetpackButtonFont
        jetpackButton.setImage(.gridicon(.plans, size: Appearance.jetpackIconSize), for: .normal)
        jetpackButton.imageEdgeInsets = Appearance.jetpackIconInsets

        // sets the background of the jp logo to white
        if let imageView = jetpackButton.imageView {
            let view = UIView()
            view.backgroundColor = .white
            view.translatesAutoresizingMaskIntoConstraints = false
            jetpackButton.insertSubview(view, belowSubview: imageView)
            view.layer.cornerRadius = Appearance.jetpackIconBackgroundSize / 2
            view.clipsToBounds = true
            NSLayoutConstraint.activate([
                view.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                view.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
                view.heightAnchor.constraint(equalToConstant: Appearance.jetpackIconBackgroundSize),
                view.widthAnchor.constraint(equalToConstant: Appearance.jetpackIconBackgroundSize)
            ])
        }

        return jetpackButton
    }

    /// Removes the Jetpack powered banner from the top of the tab bar, if it exists.
    @objc func removeJetpackBanner() {

        guard AppConfiguration.isWordPress else {
            return
        }

        jetpackBannerView?.removeFromSuperview()
        jetpackBannerView = nil
        NotificationCenter.default.post(name: .jetpackBannerToggled, object: false)
    }

    private enum Appearance {
        static let jetpackBannerHeight: CGFloat = 44
        static let jetpackBackgroundColor = UIColor(light: .muriel(color: .jetpackGreen, .shade0),
                                                    dark: .muriel(color: .jetpackGreen, .shade90))
        static let jetpackBannerTitle = NSLocalizedString("Jetpack powered",
                                                          comment: "Title of the Jetpack powered banner.")
        static let jetpackIconSize = CGSize(width: 28, height: 28)
        static let jetpackIconInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        static let jetpackButtonFont = UIFont.systemFont(ofSize: 16)
        static let jetpackIconBackgroundSize: CGFloat = 22
    }
}

extension NSNotification.Name {
    static let jetpackBannerToggled = NSNotification.Name("PoweredByJetpackBannerToggled")
}

extension UIImage {
  func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)

    guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
    defer { UIGraphicsEndImageContext() }

    let rect = CGRect(origin: .zero, size: size)
    ctx.setFillColor(color.cgColor)
    ctx.fill(rect)
    ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
    ctx.draw(image, in: rect)

    return UIGraphicsGetImageFromCurrentImageContext() ?? self
  }
}
