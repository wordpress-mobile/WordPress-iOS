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

        resetButton.setTitle("X", for: .normal)
        resetButton.isHidden = true
        stackView.addArrangedSubview(resetButton)

        mainButton.addTarget(self, action: #selector(mainButtonTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)

        addSubview(stackView)
        pinSubviewToAllEdges(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// Enables the reset button
    func enableResetButton() {
        resetButton.isHidden = false
    }

    /// Disables the reset button
    func disableResetButton() {
        resetButton.isHidden = true
    }

    @objc private func mainButtonTapped() {
        tapped?()
    }

    @objc private func resetButtonTapped() {
        resetTapped?()
    }
}
