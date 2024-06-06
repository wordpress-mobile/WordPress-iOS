import SwiftUI
import UIKit
import DesignSystem

final class MilestoneHostingController<Content: View>: UIHostingController<Content> {
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(.gridicon(.arrowUp), for: .normal)
//        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        button.accessibilityLabel = NSLocalizedString("Next notification", comment: "Accessibility label for the next notification button")
        return button
    }()

    private lazy var previousButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(.gridicon(.arrowDown), for: .normal)
//        button.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        button.accessibilityLabel = NSLocalizedString("Previous notification", comment: "Accessibility label for the previous notification button")
        return button
    }()

    func configureNavBarButtons() {
        var barButtonItems: [UIBarButtonItem] = []

        if splitViewControllerIsHorizontallyCompact {
            barButtonItems.append(makeNavigationButtons())
        }

        navigationItem.setRightBarButtonItems(barButtonItems, animated: false)
    }

    func makeNavigationButtons() -> UIBarButtonItem {
        // Create custom view to match that in NotificationDetailsViewController.
        let buttonStackView = UIStackView(arrangedSubviews: [nextButton, previousButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = .DS.Padding.split // Constants.arrowButtonSpacing

        let width = CGFloat.DS.Padding.max + .DS.Padding.split // Constants.arrowButtonSpacing
        buttonStackView.frame = CGRect(x: 0, y: 0, width: width, height: .DS.Padding.medium)

        return UIBarButtonItem(customView: buttonStackView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        makeNavigationBarTransparent()
        setupConstraints()
        configureNavBarButtons()
    }

    private func makeNavigationBarTransparent() {
        if let navigationController = navigationController {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear
            navigationController.navigationBar.isTranslucent = true
            navigationItem.standardAppearance = appearance
            navigationItem.scrollEdgeAppearance = appearance
            navigationItem.compactAppearance = appearance
        }
    }

    private func setupConstraints() {
        guard let superview = view.superview else { return }

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            view.topAnchor.constraint(equalTo: superview.topAnchor),
            view.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ])
    }
}
