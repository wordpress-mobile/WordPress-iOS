import UIKit
import PhotosUI

/// Displays a notice at the top of a media picker view in the event that the user has only given the app
/// limited photo library permissions. Contains buttons allowing the user to select more images or review their settings.
///
@available(iOS 14.0, *)
class DeviceMediaPermissionsHeader: UICollectionReusableView {

    weak var presenter: UIViewController?

    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        label.text = TextContent.message
        label.textColor = .invertedLabel
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping

        return label
    }()

    private lazy var selectButton: UIButton = {
        let selectButton = UIButton()
        configureButton(selectButton)
        selectButton.setTitle(TextContent.selectButtonTitle, for: .normal)
        selectButton.addTarget(self, action: #selector(selectMoreTapped), for: .touchUpInside)

        return selectButton
    }()

    private lazy var settingsButton: UIButton = {
        let settingsButton = UIButton()
        configureButton(settingsButton)
        settingsButton.setTitle(TextContent.settingsButtonTitle, for: .normal)
        settingsButton.addTarget(self, action: #selector(changeSettingsTapped), for: .touchUpInside)

        return settingsButton
    }()

    private let infoIcon: UIImageView = {
        let infoIcon = UIImageView(image: UIImage.gridicon(.info))
        infoIcon.translatesAutoresizingMaskIntoConstraints = false
        infoIcon.tintColor = .invertedLabel
        return infoIcon
    }()

    private let buttonStackView: UIStackView = {
        let buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = Metrics.spacing
        return buttonStackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var background: UIView!

    private func commonInit() {
        background = UIView()
        background.translatesAutoresizingMaskIntoConstraints = false
        background.backgroundColor = .invertedSystem5
        addSubview(background)

        background.layer.cornerRadius = Metrics.padding

        let outerStackView = UIStackView()
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        outerStackView.axis = .horizontal
        outerStackView.alignment = .top
        outerStackView.spacing = Metrics.padding
        outerStackView.distribution = .fill
        background.addSubview(outerStackView)

        let labelButtonsStackView = UIStackView()
        labelButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelButtonsStackView.axis = .vertical
        labelButtonsStackView.alignment = .leading
        labelButtonsStackView.distribution = .fillProportionally
        labelButtonsStackView.spacing = Metrics.spacing

        outerStackView.addArrangedSubviews([infoIcon, labelButtonsStackView])
        labelButtonsStackView.addArrangedSubviews([label, buttonStackView])
        buttonStackView.addArrangedSubviews([selectButton, settingsButton])

        activateBackgroundConstraints()

        NSLayoutConstraint.activate([
            outerStackView.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: Metrics.padding),
            outerStackView.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Metrics.padding),
            outerStackView.topAnchor.constraint(equalTo: background.topAnchor, constant: Metrics.padding),
            outerStackView.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -Metrics.padding),

            infoIcon.widthAnchor.constraint(equalTo: infoIcon.heightAnchor),
            infoIcon.widthAnchor.constraint(equalToConstant: Metrics.iconSize)
        ])

        configureViewsForContentSizeCategoryChange()
    }

    private func configureButton(_ button: UIButton) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline).bold()
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentHorizontalAlignment = .leading
        button.setTitleColor(.invertedLink, for: .normal)
    }

    private func activateBackgroundConstraints() {
        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Metrics.padding),
            background.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -Metrics.padding),
            background.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.padding),
            background.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Metrics.padding)
        ])
    }

    private func configureViewsForContentSizeCategoryChange() {
        let isAccessibilityCategory = traitCollection.preferredContentSizeCategory.isAccessibilityCategory

        buttonStackView.axis = isAccessibilityCategory ? .vertical : .horizontal
        buttonStackView.spacing = isAccessibilityCategory ? Metrics.spacing / 2.0 : Metrics.spacing

        infoIcon.isHidden = isAccessibilityCategory
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        configureViewsForContentSizeCategoryChange()
    }

    // MARK: - Actions

    @objc private func selectMoreTapped() {
        if let presenter = presenter {
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: presenter)
        }
    }

    @objc private func changeSettingsTapped() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    /// Returns the correct size for the header view, accounting for multi-line labels.
    /// We constrain it to the same width as the host view itself, and ask the system for the appropriate size.
    func referenceSizeInView(_ view: UIView) -> CGSize {
        // We'll work with just the background view, as iOS 14 has issues if we attempt to layout the header view itself.
        // We need to remove the background view from the header view while we do our calculations.
        background.removeFromSuperview()

        // Constrain the background view to match the width of the parent view
        let width = view.frame.size.width - (Metrics.padding * 2)
        let widthConstraint = background.widthAnchor.constraint(equalToConstant: width)
        widthConstraint.isActive = true
        background.layoutIfNeeded()

        // Ask the system to calculate the correct height
        let size = background.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height))

        // Put everything back how we found it
        widthConstraint.isActive = false
        addSubview(background)
        activateBackgroundConstraints()

        return CGSize(width: size.width, height: size.height + (Metrics.padding * 2))
    }

    private enum Metrics {
        static let padding: CGFloat = 8.0
        static let spacing: CGFloat = 16.0
        static let iconSize: CGFloat = 22.0
    }

    private enum TextContent {
        static let message = NSLocalizedString("Only the selected photos you've given access to are available.", comment: "Message telling the user that they've only enabled limited photo library permissions for the app.")
        static let selectButtonTitle = NSLocalizedString("Select More", comment: "Title of button that allows the user to select more photos to access within the app")
        static let settingsButtonTitle = NSLocalizedString("Change Settings", comment: "Title of button that takes user to the system Settings section for the app")
    }
}
