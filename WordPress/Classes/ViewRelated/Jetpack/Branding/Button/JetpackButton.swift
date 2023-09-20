import UIKit
import SwiftUI

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

    private func configureButton(with title: String) {
        isUserInteractionEnabled = true
        setTitle(title, for: .normal)
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
        flipInsetsForRightToLeftLayoutDirection()
        setImageBackgroundColor(imageBackgroundColor)
    }

    private enum Appearance {
        static let minimumScaleFactor: CGFloat = 0.6
        static let iconInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        static let contentInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 10)
        static let maximumFontPointSize: CGFloat = 22
        static let imageBackgroundViewMultiplier: CGFloat = 0.75
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
        if let target = target, let selector = selector {
            badge.addTarget(target, action: selector, for: .touchUpInside)
        }
        return view
    }
}
