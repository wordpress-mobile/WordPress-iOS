import SwiftUI
import UIKit
import WordPressUI
import DesignSystem

final class RegisterDomainTransferFooterView: UIView {

    // MARK: - Types

    struct Configuration {

        let title: String
        let buttonTitle: String
        let buttonAction: () -> Void

        init(
            title: String = Strings.title,
            buttonTitle: String = Strings.buttonTitle,
            buttonAction: @escaping () -> Void
        ) {
            self.title = title
            self.buttonTitle = buttonTitle
            self.buttonAction = buttonAction
        }
    }

    struct Strings {

        static let title = NSLocalizedString(
            "register.domain.transfer.title",
            value: "Looking to transfer a domain you already own?",
            comment: "The title for the transfer footer view in Register Domain screen"
        )
        static let buttonTitle = NSLocalizedString(
            "register.domain.transfer.button.title",
            value: "Transfer domain",
            comment: "The button title for the transfer footer view in Register Domain screen"
        )
    }

    // MARK: - Views

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
        label.textColor = UIColor.DS.Foreground.primary
        label.numberOfLines = 2
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let primaryButton: UIButton = {
        let button = FancyButton()
        button.titleLabel?.font = WPStyleGuide.fontForTextStyle(.headline, fontWeight: .regular)
        button.isPrimary = true
        return button
    }()

    // MARK: - Init

    init(configuration: Configuration) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor(light: .systemBackground, dark: .secondarySystemBackground)
        self.addTopBorder(withColor: .divider)
        self.setup(with: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup(with configuration: Configuration) {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, primaryButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Length.Padding.double
        stackView.distribution = .fill

        self.addSubview(stackView)

        self.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: Length.Padding.double,
            leading: Length.Padding.double,
            bottom: Length.Padding.double,
            trailing: Length.Padding.double
        )

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            readableContentGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            layoutMarginsGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])

        let action = UIAction { _ in
            configuration.buttonAction()
            WPAnalytics.track(.domainsSearchTransferDomainTapped)
        }
        self.titleLabel.text = configuration.title
        self.primaryButton.setTitle(configuration.buttonTitle, for: .normal)
        self.primaryButton.addAction(action, for: .touchUpInside)
    }

}
