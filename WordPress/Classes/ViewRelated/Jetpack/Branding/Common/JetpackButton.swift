import UIKit
import SwiftUI

/// A "Jetpack powered" button with two different styles (`badge` or    `banner`)
class JetpackButton: UIButton {

    enum ButtonStyle {
        case badge
        case banner
    }

    private let style: ButtonStyle

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
        setTitle(Appearance.jetpackBadgeTitle, for: .normal)
        tintColor = buttonTintColor
        backgroundColor = buttonBackgroundColor
        setTitleColor(buttonTitleColor, for: .normal)
        titleLabel?.font = Appearance.jetpackBadgeFont
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.minimumScaleFactor = Appearance.minimumScaleFactor
        titleLabel?.adjustsFontSizeToFitWidth = true
        setImage(.gridicon(.plans, size: Appearance.jetpackIconSize), for: .normal)
        imageEdgeInsets = Appearance.jetpackIconInsets

        // sets the background of the jp logo to white
        if let imageView = imageView {
            let view = UIView()
            view.backgroundColor = imageBackgroundColor
            view.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(view, belowSubview: imageView)
            view.layer.cornerRadius = Appearance.jetpackIconBackgroundSize.width / 2
            view.clipsToBounds = true
            NSLayoutConstraint.activate([
                view.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                view.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
                view.heightAnchor.constraint(equalToConstant: Appearance.jetpackIconBackgroundSize.height),
                view.widthAnchor.constraint(equalToConstant: Appearance.jetpackIconBackgroundSize.width)
            ])
        }
    }

    private enum Appearance {
        static let jetpackBadgeTitle = NSLocalizedString("Jetpack powered",
                                                         comment: "Title of the Jetpack powered badge.")
        static let defaultButtonHeight: CGFloat = 34
        static let defaultButtonWidth: CGFloat = 180
        static let jetpackBadgeFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        static let minimumScaleFactor: CGFloat = 0.6
        static let jetpackIconSize = CGSize(width: 24, height: 24)
        static let jetpackIconInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        static let jetpackIconBackgroundSize = CGSize(width: 20, height: 20)
    }
}

/// Default "Jetpack powered" badge
extension JetpackButton {

    /// Instantiates the default, fixed size "Jetpack powered" badge (`width: 180`, `height: 34`).
    /// You should not set width or height constraints on this instance.
    /// If you need to do so, create your own `JetpackButton` instance, instead.
    /// - Returns: an instance of JetpackButton of with `.badge` style and fixed size and rounded corners.
    static func makeDefaultBadge() -> JetpackButton {
        let button = JetpackButton(style: .badge)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = Appearance.defaultButtonHeight / 2
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: Appearance.defaultButtonHeight),
            button.widthAnchor.constraint(equalToConstant: Appearance.defaultButtonWidth)
        ])
        return button
    }
}
