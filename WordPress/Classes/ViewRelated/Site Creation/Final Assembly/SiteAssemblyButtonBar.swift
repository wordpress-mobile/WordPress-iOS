import UIKit

/// The bottom-pinned bar hosting the single "Done" button shown when site
/// assembly succeeds. Replaces the storyboard-based `NUXButtonViewController`
/// previously reused from WordPressAuthenticator.
final class SiteAssemblyButtonBar: UIView {

    /// Invoked when the button is tapped.
    var onTap: (() -> Void)?

    private let button: UIButton

    init(buttonTitle: String, showsTopShadow: Bool) {
        self.button = UIButton.makePrimaryNUXButton()

        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        button.translatesAutoresizingMaskIntoConstraints = false
        button.configuration?.title = buttonTitle
        // A stable identifier for UI automation, intentionally not derived from
        // the localized title.
        button.accessibilityIdentifier = "Done Button"
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 16),
            bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: 16),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])

        if showsTopShadow {
            let shadowView = UIImageView(image: UIImage(named: "darkgrey-shadow"))
            shadowView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(shadowView)

            NSLayoutConstraint.activate([
                // The shadow hangs above the bar's top edge, matching the layout
                // of the storyboard this view replaces.
                shadowView.heightAnchor.constraint(equalToConstant: 10),
                shadowView.bottomAnchor.constraint(equalTo: topAnchor),
                shadowView.leadingAnchor.constraint(equalTo: leadingAnchor),
                shadowView.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func buttonTapped() {
        onTap?()
    }
}
