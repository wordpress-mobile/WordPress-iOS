import Foundation
import UIKit

final class JetpackPoweredViewController: UIViewController {
    private enum Constants {
        enum Constraints {
            static let animationViewTop: CGFloat = 70
            static let titleLabelTop: CGFloat = 45
            static let titleLabelHorizontal: CGFloat = 30
            static let descriptionLabelTop: CGFloat = 10
            static let redirectButtonTop: CGFloat = 50
        }
    }

    // Temporary
    private let animationView = UIView()

    private let titleLabel: UILabel = {
        $0.font = WPStyleGuide.fontForTextStyle(.title1)
        return $0
    }(UILabel())

    private let descriptionLabel: UILabel = {
        $0.font = WPStyleGuide.fontForTextStyle(.title3)
        return $0
    }(UILabel())

    private let redirectButton: UIButton = {
        $0.backgroundColor = UIColor(
            light: .muriel(color: .jetpackGreen, .shade40),
            dark: .muriel(color: .jetpackGreen, .shade40)
        )
        return $0
    }(UIButton())

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubviews([animationView, titleLabel, descriptionLabel, redirectButton])
        setUpConstraints()
    }

    private func setUpConstraints() {
        animationView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        redirectButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Constraints.animationViewTop),
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: animationView.topAnchor, constant: Constants.Constraints.titleLabelTop),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.Constraints.titleLabelHorizontal),
            view.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: Constants.Constraints.titleLabelHorizontal),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Constants.Constraints.descriptionLabelTop),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            redirectButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: Constants.Constraints.redirectButtonTop),
            redirectButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            redirectButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }
}
