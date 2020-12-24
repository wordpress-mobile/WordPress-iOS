import Foundation

/// A button that represents a filter chip
///
class FilterChipButton: UIView {
    /// The title of the button
    var title: String? {
        didSet {
            mainButton.setTitle(title, for: .normal)
        }
    }

    let mainButton = UIButton(type: .system)
    let resetButton = UIButton(type: .system)

    /// Callback called when the button is tapped
    var tapped: (() -> Void)?

    /// Callback called when the reset ("X") is tapped
    var resetTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let stackView = UIStackView()
        stackView.axis = .horizontal

        stackView.addArrangedSubview(mainButton)

        resetButton.widthAnchor.constraint(greaterThanOrEqualToConstant: Constants.minResetButtonWidth).isActive = true
        resetButton.imageEdgeInsets = Constants.resetImageInsets
        resetButton.isHidden = true
        stackView.addArrangedSubview(resetButton)

        mainButton.addTarget(self, action: #selector(mainButtonTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)

        addSubview(stackView)
        pinSubviewToAllEdges(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        layer.borderWidth = Constants.borderWidth
        layer.cornerRadius = Constants.cornerRadius

        mainButton.titleLabel?.font = WPStyleGuide.fontForTextStyle(.callout)
        mainButton.setTitleColor(.text, for: .normal)
        mainButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.minButtonHeight).isActive = true
        mainButton.contentEdgeInsets = Constants.buttonContentInset

        applyColors()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// Enables the reset button
    func enableResetButton() {
        resetButton.isHidden = false
        mainButton.contentEdgeInsets = Constants.buttonContentInsetWithResetEnabled
    }

    /// Disables the reset button
    func disableResetButton() {
        resetButton.isHidden = true
        mainButton.contentEdgeInsets = Constants.buttonContentInset
        UIAccessibility.post(notification: .layoutChanged, argument: mainButton)
    }

    @objc private func mainButtonTapped() {
        tapped?()
    }

    @objc private func resetButtonTapped() {
        resetTapped?()
    }

    private func applyColors() {
        layer.borderColor = UIColor.textQuaternary.cgColor
        resetButton.setImage(UIImage.gridicon(.crossCircle), for: .normal)
        resetButton.tintColor = .textSubtle
    }

    private enum Constants {
        static let minResetButtonWidth: CGFloat = 32
        static let resetImageInsets = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 10).flippedForRightToLeft
        static let borderWidth: CGFloat = 1
        static let cornerRadius: CGFloat = 16
        static let minButtonHeight: CGFloat = 32
        static let buttonContentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12).flippedForRightToLeft
        static let buttonContentInsetWithResetEnabled = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0).flippedForRightToLeft
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyColors()
        }
    }
}
