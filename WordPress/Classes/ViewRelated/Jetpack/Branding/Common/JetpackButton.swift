import UIKit
import SwiftUI

/// A "Jetpack powered" button with two different styles (`badge` or    `banner`)
class JetpackButton: UIButton {

    enum ButtonStyle {
        case badge
        case banner
    }

    private let style: ButtonStyle

    private lazy var imageBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = imageBackgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(style: ButtonStyle) {
        self.style = style
        super.init(frame: .zero)
        configureButton()
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard instantiation not supported.")
    }

    private var buttonBackgroundColor: UIColor {
        switch style {
        case .badge:
            return UIColor(light: .muriel(color: .jetpackGreen, .shade40),
                           dark: .muriel(color: .jetpackGreen, .shade90))
        case .banner:
            return .clear
        }
    }

    private var buttonTintColor: UIColor {
        switch style {
        case .badge:
            return UIColor(light: .white,
                           dark: .muriel(color: .jetpackGreen, .shade40))
        case .banner:
            return .muriel(color: .jetpackGreen, .shade40)
        }
    }

    private var buttonTitleColor: UIColor {
        switch style {
        case .badge:
            return .white
        case .banner:
            return UIColor(light: .black, dark: .white)
        }
    }

    private var imageBackgroundColor: UIColor {
        switch style {
        case .badge:
            return UIColor(light: .muriel(color: .jetpackGreen, .shade40),
                           dark: .white)
        case .banner:
            return .white
        }
    }

    private func configureButton() {
        // TODO: Remove this when the modal presentation is added
        isUserInteractionEnabled = false
        setTitle(Appearance.title, for: .normal)
        tintColor = buttonTintColor
        backgroundColor = buttonBackgroundColor
        setTitleColor(buttonTitleColor, for: .normal)
        titleLabel?.font = Appearance.titleFont
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.minimumScaleFactor = Appearance.minimumScaleFactor
        titleLabel?.adjustsFontSizeToFitWidth = true
        setImage(.gridicon(.plans), for: .normal)
        contentVerticalAlignment = .fill
        contentMode = .scaleAspectFit
        imageEdgeInsets = Appearance.iconInsets
        contentEdgeInsets = Appearance.contentInsets
        imageView?.contentMode = .scaleAspectFit
        adjustsImageSizeForAccessibilityContentSizeCategory = true

        // sets the background of the jp logo to white
        if let imageView = imageView {
            insertSubview(imageBackgroundView, belowSubview: imageView)
            imageBackgroundView.clipsToBounds = true
            NSLayoutConstraint.activate([
                imageBackgroundView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                imageBackgroundView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
                imageBackgroundView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: Appearance.imageBackgroundViewMultiplier),
                imageBackgroundView.widthAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: Appearance.imageBackgroundViewMultiplier),
            ])
        }
    }

    private enum Appearance {
        static let title = NSLocalizedString("jetpack.branding.badge_banner.title", value: "Jetpack powered",
                                             comment: "Title of the Jetpack powered badge.")
        static let minimumScaleFactor: CGFloat = 0.6
        static let iconInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        static let contentInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 10)
        static let maximumFontPointSize: CGFloat = 30
        static let imageBackgroundViewMultiplier: CGFloat = 0.75
        static var titleFont: UIFont {
            let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            return UIFont(descriptor: fontDescriptor, size: min(fontDescriptor.pointSize, maximumFontPointSize))
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageBackgroundView.layer.cornerRadius = imageBackgroundView.frame.height / 2
        if style == .badge {
            layer.cornerRadius = frame.height / 2
            layer.cornerCurve = .continuous
        }
    }
}
