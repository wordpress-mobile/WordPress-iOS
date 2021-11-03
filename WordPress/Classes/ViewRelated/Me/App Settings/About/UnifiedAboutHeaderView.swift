import Foundation
import SwiftUI

final class UnifiedAboutHeaderView: UIView {

    // MARK: - Customization Support

    struct AppInfo {
        let icon: UIImage
        let name: String
        let version: String
    }

    struct Spacing {
        let betweenAppIconAndAppNameLabel: CGFloat
        let betweenAppNameLabelAndAppVersionLabel: CGFloat
        let aboveAndBelowHeaderView: CGFloat
    }

    struct Sizing {
        let appIconWidthAndHeight: CGFloat
        let appIconCornerRadius: CGFloat
    }

    struct Fonts {
        let appName: UIFont
        let appVersion: UIFont
    }

    // MARK: - Defaults

    public static let defaultSizing = Sizing(
        appIconWidthAndHeight: CGFloat(80),
        appIconCornerRadius: CGFloat(13))

    public static let defaultSpacing = Spacing(
        betweenAppIconAndAppNameLabel: CGFloat(16),
        betweenAppNameLabelAndAppVersionLabel: CGFloat(4),
        aboveAndBelowHeaderView: CGFloat(64))

    // MARK: - View Customization

    private let appInfo: AppInfo
    private let spacing: Spacing
    private let sizing: Sizing
    private let fonts: Fonts

    // MARK: - Initializers

    init(appInfo: AppInfo,
         sizing: Sizing = defaultSizing,
         spacing: Spacing = defaultSpacing,
         fonts: Fonts) {

        self.appInfo = appInfo
        self.sizing = sizing
        self.spacing = spacing
        self.fonts = fonts

        super.init(frame: .zero)

        setupSubviews()
    }

    override init(frame: CGRect) {
        fatalError("Initializer not implemented!")
    }

    required init?(coder: NSCoder) {
        fatalError("Initializer not implemented!")
    }

    // MARK: - Setting up the subviews

    func setupSubviews() {
        let stackView = UIStackView()
        let iconView = UIImageView()
        let appNameLabel = UILabel()
        let appVersionLabel = UILabel()

        clipsToBounds = true

        appNameLabel.text = appInfo.name
        appNameLabel.lineBreakMode = .byWordWrapping
        appNameLabel.numberOfLines = 1
        appNameLabel.font = fonts.appName

        appVersionLabel.text = appInfo.version
        appVersionLabel.lineBreakMode = .byWordWrapping
        appVersionLabel.numberOfLines = 1
        appVersionLabel.font = fonts.appVersion
        appVersionLabel.textColor = UIColor.colorFromHex("8A898E")

        iconView.image = appInfo.icon
        iconView.layer.cornerRadius = sizing.appIconCornerRadius
        iconView.layer.masksToBounds = true

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubviews([
            iconView,
            appNameLabel,
            appVersionLabel,
        ])
        stackView.setCustomSpacing(spacing.betweenAppIconAndAppNameLabel, after: iconView)
        stackView.setCustomSpacing(spacing.betweenAppNameLabelAndAppVersionLabel, after: appNameLabel)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            iconView.heightAnchor.constraint(equalToConstant: sizing.appIconWidthAndHeight),
            iconView.widthAnchor.constraint(equalToConstant: sizing.appIconWidthAndHeight),
        ])

        NSLayoutConstraint.activate([
            appNameLabel.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            appVersionLabel.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
        ])

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: spacing.aboveAndBelowHeaderView),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -spacing.aboveAndBelowHeaderView),
        ])
    }
}
