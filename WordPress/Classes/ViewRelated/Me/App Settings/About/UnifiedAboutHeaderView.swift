import Foundation
import UIKit


/// Defines the content of the header that appears on the top level about screen.
struct AboutScreenAppInfo {
    /// The app's name
    let name: String
    /// The current build version of the app
    let version: String
    /// The app's icon
    let icon: UIImage
}

struct AboutScreenFonts {
    let appName: UIFont
    let appVersion: UIFont

    static let defaultFonts: AboutScreenFonts = {
        // Title is serif semibold large title
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
        let serifFontDescriptor = fontDescriptor.withDesign(.serif) ?? fontDescriptor
        let traits = [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]
        let descriptor = serifFontDescriptor.addingAttributes([.traits: traits])

        let font = UIFont(descriptor: descriptor, size: descriptor.pointSize)
        return AboutScreenFonts(appName: font,
                                appVersion: .preferredFont(forTextStyle: .callout))
    }()
}

final class UnifiedAboutHeaderView: UIView {

    // MARK: - Customization Support

    struct Spacing {
        let betweenAppIconAndAppNameLabel: CGFloat
        let betweenAppNameLabelAndAppVersionLabel: CGFloat
        let aboveAndBelowHeaderView: CGFloat
    }

    struct Sizing {
        let appIconWidthAndHeight: CGFloat
        let appIconCornerRadius: CGFloat
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

    private let appInfo: AboutScreenAppInfo
    private let spacing: Spacing
    private let sizing: Sizing
    private let fonts: AboutScreenFonts
    private let dismissAction: (() -> Void)?

    // MARK: - Initializers

    init(appInfo: AboutScreenAppInfo,
         sizing: Sizing = defaultSizing,
         spacing: Spacing = defaultSpacing,
         fonts: AboutScreenFonts,
         dismissAction: (() -> Void)? = nil) {

        self.appInfo = appInfo
        self.sizing = sizing
        self.spacing = spacing
        self.fonts = fonts
        self.dismissAction = dismissAction

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
        let stackView = makeStackView()
        let iconView = makeIconView()
        let appNameLabel = makeAppNameLabel()
        let appVersionLabel = makeAppVersionLabel()
        let closeButton = makeCloseButton()

        clipsToBounds = true

        stackView.addArrangedSubviews([
            iconView,
            appNameLabel,
            appVersionLabel,
        ])
        stackView.setCustomSpacing(spacing.betweenAppIconAndAppNameLabel, after: iconView)
        stackView.setCustomSpacing(spacing.betweenAppNameLabelAndAppVersionLabel, after: appNameLabel)

        addSubview(stackView)
        addSubview(closeButton)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            iconView.heightAnchor.constraint(equalToConstant: sizing.appIconWidthAndHeight),
            iconView.widthAnchor.constraint(equalToConstant: sizing.appIconWidthAndHeight),

            appNameLabel.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            appVersionLabel.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),

            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: spacing.aboveAndBelowHeaderView),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -spacing.aboveAndBelowHeaderView),

            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.closeButtonInset),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.closeButtonInset),
            closeButton.widthAnchor.constraint(equalToConstant: Metrics.closeButtonRadius),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor)
        ])
    }

    // MARK: - Subviews

    private func makeStackView() -> UIStackView {
        let stackView = UIStackView()

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }

    private func makeAppNameLabel() -> UILabel {
        let appNameLabel = UILabel()

        appNameLabel.text = appInfo.name
        appNameLabel.lineBreakMode = .byWordWrapping
        appNameLabel.numberOfLines = 1
        appNameLabel.font = fonts.appName
        return appNameLabel
    }

    private func makeAppVersionLabel() -> UILabel {
        let appVersionLabel = UILabel()

        appVersionLabel.text = appInfo.version
        appVersionLabel.lineBreakMode = .byWordWrapping
        appVersionLabel.numberOfLines = 1
        appVersionLabel.font = fonts.appVersion
        appVersionLabel.textColor = .secondaryLabel
        return appVersionLabel
    }

    private func makeIconView() -> UIImageView {
        let iconView = UIImageView()

        iconView.image = appInfo.icon
        iconView.layer.cornerRadius = sizing.appIconCornerRadius
        iconView.layer.masksToBounds = true
        return iconView
    }

    private func makeCloseButton() -> UIButton {
        let closeButton = UIButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        let configuration = UIImage.SymbolConfiguration(pointSize: Metrics.closeButtonSymbolSize, weight: .bold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.backgroundColor = .quaternarySystemFill
        closeButton.layer.cornerRadius = Metrics.closeButtonRadius * 0.5
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        // Hide if we don't have a dismiss action
        closeButton.isHidden = (dismissAction == nil)

        return closeButton
    }


    // MARK: - Actions

    @objc private func closeButtonTapped() {
        dismissAction?()
    }

    // MARK: - Constants

    private enum Metrics {
        static let closeButtonRadius: CGFloat = 30
        static let closeButtonInset: CGFloat = 16
        static let closeButtonSymbolSize: CGFloat = 16
    }
}
