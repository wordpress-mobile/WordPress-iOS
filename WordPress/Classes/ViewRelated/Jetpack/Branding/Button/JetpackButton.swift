import UIKit
import SwiftUI
import WordPressUI

/// A "Jetpack powered" button with two different styles (`badge` or    `banner`)
class JetpackButton: CircularImageButton {

    enum ButtonStyle {
        case badge
        case banner
    }

    var title: String? {
        didSet {
            setTitle(title, for: .normal)
        }
    }

    private let style: ButtonStyle

    init(style: ButtonStyle, title: String) {
        self.style = style
        super.init(frame: .zero)
        configureButton(with: title)
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard instantiation not supported.")
    }

    private var buttonBackgroundColor: UIColor {
        switch style {
        case .badge:
            return UIColor(
                light: UIAppColor.jetpackGreen(.shade40),
                dark: UIAppColor.jetpackGreen(.shade90)
            )
        case .banner:
            return .clear
        }
    }

    private var buttonTintColor: UIColor {
        return switch style {
        case .badge: UIColor(light: .white, dark: UIAppColor.jetpackGreen(.shade40))
        case .banner: UIAppColor.jetpackGreen(.shade40)
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
        return switch style {
        case .badge: UIColor(light: UIAppColor.jetpackGreen(.shade40), dark: .white)
        case .banner: .white
        }
    }

    private func configureButton(with title: String) {
        isUserInteractionEnabled = true
        setTitle(title, for: .normal)
        tintColor = buttonTintColor
        backgroundColor = buttonBackgroundColor
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.minimumScaleFactor = Appearance.minimumScaleFactor
        titleLabel?.adjustsFontSizeToFitWidth = true
        contentMode = .scaleAspectFit

        let iconColor = buttonTintColor
        var configuration = UIButton.Configuration.plain()
        configuration.image = .gridicon(.plans)
        configuration.imagePadding = Appearance.iconPadding
        configuration.contentInsets = Appearance.contentInsets
        configuration.baseForegroundColor = buttonTitleColor
        configuration.imageColorTransformer = UIConfigurationColorTransformer { _ in iconColor }
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Appearance.titleFont
            return attributes
        }
        self.configuration = configuration

        imageView?.contentMode = .scaleAspectFit
        setImageBackgroundColor(imageBackgroundColor)
    }

    private enum Appearance {
        static let minimumScaleFactor: CGFloat = 0.6
        static let iconPadding: CGFloat = 10
        static let contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 10)
        static let maximumFontPointSize: CGFloat = 22
        static var titleFont: UIFont {
            let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .callout)
            let font = UIFont(descriptor: fontDescriptor, size: min(fontDescriptor.pointSize, maximumFontPointSize))
            return UIFontMetrics.default.scaledFont(for: font, maximumPointSize: maximumFontPointSize)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if style == .badge {
            layer.cornerRadius = frame.height / 2
            layer.cornerCurve = .continuous
        }
    }
}

// MARK: Badge view
extension JetpackButton {

    /// Instantiates a view containing a Jetpack powered badge
    /// - Parameter title: Title of the button
    /// - Parameter topPadding: top padding, defaults to 30 pt
    /// - Parameter bottomPadding: bottom padding, defaults to 30 pt
    /// - Parameter target: optional target for the button action
    /// - Parameter selector: optional selector for the button action
    /// - Returns: the view containing the badge
    @objc
    static func makeBadgeView(title: String,
                              topPadding: CGFloat = 30,
                              bottomPadding: CGFloat = 30,
                              target: Any? = nil,
                              selector: Selector? = nil) -> UIView {
        let view = UIView()
        let badge = JetpackButton(style: .badge, title: title)
        badge.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(badge)
        NSLayoutConstraint.activate([
            badge.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            badge.topAnchor.constraint(equalTo: view.topAnchor, constant: topPadding),
            badge.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomPadding)
        ])
        if let target, let selector {
            badge.addTarget(target, action: selector, for: .touchUpInside)
        }
        return view
    }
}
