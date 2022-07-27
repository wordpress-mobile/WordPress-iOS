import Foundation
import UIKit

final class JetpackPoweredViewController: UIViewController {
    private enum Constants {
        enum Constraints {
            static let animationViewTop: CGFloat = 70
            static let animationViewHeight: CGFloat = 80
            static let animationViewWidth: CGFloat = 147
            static let titleLabelTop: CGFloat = 45
            static let titleLabelHorizontal: CGFloat = 30
            static let descriptionLabelTop: CGFloat = 10
            static let redirectButtonTop: CGFloat = 50
            static let redirectButtonHeight: CGFloat = 50
            static let redirectButtonBottom: CGFloat = 60
        }

        enum Strings {
            static let title = NSLocalizedString(
                "jetpack.powered.title",
                value: "Jetpack powered",
                comment: "Title for Jetpack Powered bottom sheet."
            )

            static let description = NSLocalizedString(
                "jetpack.powered.description",
                value: "Stats, Reader, Notifications, and other features are provided by Jetpack.",
                comment: "Description for Jetpack Powered bottom sheet."
            )

            static let buttonTitle = NSLocalizedString(
                "jetpack.powered.button.title",
                value: "Get the new Jetpack app",
                comment: "Button title for Jetpack Powered bottom sheet."
            )
        }
    }

    // Placeholder. Replace with Lottie View for animation.
    private let animationView = UIView()

    private let titleLabel: UILabel = {
        $0.font = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .bold)
        $0.textAlignment = .center
        $0.numberOfLines = 2
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.text = Constants.Strings.title
        return $0
    }(UILabel())

    private let descriptionLabel: UILabel = {
        $0.font = WPStyleGuide.fontForTextStyle(.subheadline)
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.setContentHuggingPriority(.required, for: .vertical)
        $0.text = Constants.Strings.description
        return $0
    }(UILabel())

    private let redirectButton: UIButton = {
        $0.backgroundColor = UIColor(
            light: .muriel(color: .jetpackGreen, .shade40),
            dark: .muriel(color: .jetpackGreen, .shade40)
        )
        $0.layer.cornerRadius = 6
        $0.setTitle(Constants.Strings.buttonTitle, for: .normal)
        return $0
    }(UIButton())

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubviews([animationView, titleLabel, descriptionLabel, redirectButton])
        configureUI()
        setUpConstraints()
    }

    private func configureUI() {
        view.backgroundColor = UIColor(
            light: .muriel(color: .jetpackGreen, .shade0),
            dark: .muriel(color: .jetpackGreen, .shade100)
        )
    }

    private func setUpConstraints() {
        animationView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        redirectButton.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Constraints.animationViewTop),
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.heightAnchor.constraint(equalToConstant: Constants.Constraints.animationViewHeight),
            animationView.widthAnchor.constraint(equalToConstant: Constants.Constraints.animationViewWidth),
            titleLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: Constants.Constraints.titleLabelTop),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.Constraints.titleLabelHorizontal),
            view.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: Constants.Constraints.titleLabelHorizontal),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Constants.Constraints.descriptionLabelTop),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            redirectButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: Constants.Constraints.redirectButtonTop),
            redirectButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            redirectButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            redirectButton.heightAnchor.constraint(equalToConstant: Constants.Constraints.redirectButtonHeight)
        ])
    }

    static func height(maxContentWidth: CGFloat) -> CGFloat {
        var totalHeight: CGFloat = 0
        totalHeight += Constants.Constraints.animationViewTop
        totalHeight += Constants.Constraints.animationViewHeight
        totalHeight += Constants.Constraints.titleLabelTop
        totalHeight += Constants.Strings.title.height(withMaxWidth: maxContentWidth, font: WPStyleGuide.fontForTextStyle(.title1))
        totalHeight += Constants.Constraints.descriptionLabelTop
        totalHeight += Constants.Strings.description.height(withMaxWidth: maxContentWidth, font: WPStyleGuide.fontForTextStyle(.subheadline))
        totalHeight += Constants.Constraints.redirectButtonTop
        totalHeight += Constants.Constraints.redirectButtonHeight
        totalHeight += Constants.Constraints.redirectButtonBottom
        return totalHeight
    }
}

extension JetpackPoweredViewController: DrawerPresentable {
    var collapsedHeight: DrawerHeight {
        return .intrinsicHeight
    }
}
