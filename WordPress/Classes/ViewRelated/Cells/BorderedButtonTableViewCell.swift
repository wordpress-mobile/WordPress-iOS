import UIKit

// UITableViewCell that displays a full width button with a border.
// Properties:
// - normalColor: used for the button label and border.
// - highlightedColor: used for the button label when the button is pressed.
// - buttonInsets: used to provide margins around the button within the cell.
// The delegate is notified when the button is tapped.

protocol BorderedButtonTableViewCellDelegate: AnyObject {
    func buttonTapped()
}

class BorderedButtonTableViewCell: UITableViewCell {

    // MARK: - Properties

    weak var delegate: BorderedButtonTableViewCellDelegate?

    private var buttonTitle = String()
    private var buttonInsets = Defaults.buttonInsets
    private var titleFont = Defaults.titleFont
    private var normalColor = Defaults.normalColor
    private var highlightedColor = Defaults.highlightedColor

    // MARK: - Configure

    func configure(buttonTitle: String,
                   titleFont: UIFont = Defaults.titleFont,
                   normalColor: UIColor = Defaults.normalColor,
                   highlightedColor: UIColor = Defaults.highlightedColor,
                   buttonInsets: UIEdgeInsets = Defaults.buttonInsets) {
        self.buttonTitle = buttonTitle
        self.titleFont = titleFont
        self.normalColor = normalColor
        self.highlightedColor = highlightedColor
        configureView()
    }

}

// MARK: - Private Extension

private extension BorderedButtonTableViewCell {

    func configureView() {
        selectionStyle = .none
        accessibilityTraits = .button

        let button = configuredButton()
        contentView.addSubview(button)
        contentView.pinSubviewToAllEdges(button, insets: buttonInsets)
    }

    func configuredButton() -> UIButton {
        let button = UIButton()
        let buttonColor = normalColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(buttonTitle, for: .normal)
        button.setTitleColor(buttonColor, for: .normal)
        button.setTitleColor(highlightedColor, for: .highlighted)
        button.setBackgroundImage(UIImage.renderBackgroundImage(fill: .clear, border: buttonColor), for: .normal)
        button.setBackgroundImage(.renderBackgroundImage(fill: buttonColor, border: buttonColor), for: .highlighted)

        button.titleLabel?.font = titleFont
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0

        // Add constraints to the title label, so the button can contain it properly in multi-line cases.
        if let label = button.titleLabel {
            button.pinSubviewToAllEdgeMargins(label)
        }

        button.on(.touchUpInside) { [weak self] _ in
            self?.delegate?.buttonTapped()
        }

        return button
    }

    struct Defaults {
        static let buttonInsets = UIEdgeInsets(top: 4, left: 20, bottom: 4, right: 20)
        static let titleFont = WPStyleGuide.fontForTextStyle(.body, fontWeight: .semibold)
        static let normalColor: UIColor = .text
        static let highlightedColor: UIColor = .white
    }

}
