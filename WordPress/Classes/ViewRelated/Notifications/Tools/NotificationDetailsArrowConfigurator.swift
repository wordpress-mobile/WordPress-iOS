import UIKit
import DesignSystem

final class NotificationDetailsArrowConfigurator {
    private let nextAction: (() -> Void)?
    private let previousAction: (() -> Void)?

    init(nextAction: (() -> Void)?, previousAction: (() -> Void)?) {
        self.nextAction = nextAction
        self.previousAction = previousAction
    }

    func makeNavigationButtons() -> UIBarButtonItem {
        let buttonStackView = UIStackView(arrangedSubviews: [createNextButton(), createPreviousButton()])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = .DS.Padding.split

        let width = CGFloat.DS.Padding.max + .DS.Padding.split
        buttonStackView.frame = CGRect(x: 0, y: 0, width: width, height: .DS.Padding.medium)

        return UIBarButtonItem(customView: buttonStackView)
    }

    private func createPreviousButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(.gridicon(.arrowDown), for: .normal)
        button.accessibilityLabel = NSLocalizedString("Next notification", comment: "Accessibility label for the next notification button")
        button.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        button.isEnabled = previousAction != nil
        return button
    }

    private func createNextButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(.gridicon(.arrowUp), for: .normal)
        button.accessibilityLabel = NSLocalizedString("Previous notification", comment: "Accessibility label for the previous notification button")
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        button.isEnabled = nextAction != nil
        return button
    }

    @objc private func previousButtonTapped() {
        previousAction?()
    }

    @objc private func nextButtonTapped() {
        nextAction?()
    }
}
