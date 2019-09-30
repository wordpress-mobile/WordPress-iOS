
import UIKit

import Gridicons
import WordPressAuthenticator

// MARK: ErrorStateView

/// This view is intended for use as the root view of `ErrorStateViewController`.
/// It manages the presentation of the various error states that can arise during the process of site creation.
///
final class ErrorStateView: UIView {

    // MARK: Properties

    /// A collection of parameters uses for animation & layout of the view.
    private struct Parameters {
        static let dismissalDimension           = CGFloat(16)
        static let dismissalInsetScaleFactor    = CGFloat(0.05)
        static let iPadWidth                    = CGFloat(512)
        static let iPhoneWidthScaleFactor       = CGFloat(0.79)
        static let retryTopPadding              = CGFloat(6)
        static let stackViewSpacing             = CGFloat(10)
        static let supportTopInset              = CGFloat(26)
    }

    /// This informs constraints applied to the view.
    var preferredWidth: CGFloat {
        let preferredWidth: CGFloat

        if WPDeviceIdentification.isiPad() {
            preferredWidth = Parameters.iPadWidth
        } else {
            let screenBounds = UIScreen.main.bounds
            preferredWidth = screenBounds.width * Parameters.iPhoneWidthScaleFactor
        }

        return preferredWidth
    }

    /// The configuration of the error state view to apply.
    private let configuration: ErrorStateViewConfiguration

    /// This represents a "Dismiss" image view. It is visible when the configuration specifies a handler.
    private(set) var dismissalImageView: UIImageView?

    /// This represents the "headline" of the error message presented to the user.
    private(set) var titleLabel: UILabel

    /// This represents the "subtitle" of the error message presented to the user.
    private(set) var subtitleLabel: UILabel?

    /// This represents the "Retry" button associated with the error presentation. Visible when a handler is set.
    private(set) var retryButton: UIButton?

    /// This represents a container to add additional padding to the "Retry" button.
    private(set) var retryContainerView: UIView?

    /// This represents the "Contact support" of the error message presented to the user. Visible when a handler is set.
    private(set) var contactSupportLabel: UILabel?

    /// The stack view manages the central content of the stack view
    private(set) var contentStackView: UIStackView

    // MARK: ErrorStateView

    /// The designated initializer.
    ///
    /// - Parameter configuration: the configuration with which to instantiate this error state view.
    init(with configuration: ErrorStateViewConfiguration) {
        self.configuration = configuration

        self.titleLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0

            label.font = WPStyleGuide.fontForTextStyle(.title2)
            label.textColor = .neutral(.shade40)
            label.textAlignment = .center

            label.text = configuration.title
            label.sizeToFit()

            return label
        }()

        self.contentStackView = {
            let stackView = UIStackView()

            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .vertical
            stackView.alignment = .center
            stackView.spacing = Parameters.stackViewSpacing

            return stackView
        }()

        if let subtitleText = configuration.subtitle {
            self.subtitleLabel = {
                let label = UILabel()

                label.translatesAutoresizingMaskIntoConstraints = false
                label.numberOfLines = 0

                label.font = WPStyleGuide.fontForTextStyle(.body, fontWeight: .regular)
                label.textColor = .neutral(.shade70)
                label.textAlignment = .center

                label.text = subtitleText
                label.sizeToFit()

                return label
            }()
        }

        if let _ = configuration.retryActionHandler {
            self.retryButton = {
                let button = NUXButton(frame: .zero)

                button.translatesAutoresizingMaskIntoConstraints = false
                button.isPrimary = true

                let titleText = NSLocalizedString("Retry",
                                                  comment: "If a user taps the button with this label, the action that evinced this error view will be retried.")
                button.setTitle(titleText, for: .normal)

                return button
            }()
        }

        if let _ = configuration.contactSupportActionHandler {
            self.contactSupportLabel = {
                let label = UILabel()

                label.translatesAutoresizingMaskIntoConstraints = false
                label.numberOfLines = 0

                label.font = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .medium)
                label.textColor = .primary
                label.textAlignment = .center

                label.text = NSLocalizedString("Contact Support",
                                               comment: "If a user taps this label, the app will navigate to the Support view.")
                label.sizeToFit()

                return label
            }()
        }

        if let _ = configuration.dismissalActionHandler {
            self.dismissalImageView = {
                let dismissImage = Gridicon.iconOfType(.cross)
                let imageView = UIImageView(image: dismissImage)

                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.contentMode = .scaleAspectFit
                imageView.tintColor = .primary

                return imageView
            }()
        }

        super.init(frame: .zero)

        configure()
    }

    // MARK: UIView

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private behavior

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false

        configureContentStackView()
        configureSupportLabelIfNeeded()
        configureDismissalViewIfNeeded()
    }

    private func configureContentStackView() {
        contentStackView.addArrangedSubview(titleLabel)

        addSubview(contentStackView)

        if let subtitle = subtitleLabel {
            contentStackView.addArrangedSubview(subtitle)
        }

        if let retryButton = retryButton {
            retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

            let containerView = UIView(frame: .zero)

            containerView.translatesAutoresizingMaskIntoConstraints = false

            containerView.addSubview(retryButton)
            contentStackView.addArrangedSubview(containerView)

            NSLayoutConstraint.activate([
                containerView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor),
                containerView.heightAnchor.constraint(equalTo: retryButton.heightAnchor),
                retryButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                retryButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Parameters.retryTopPadding)
            ])

            self.retryContainerView = containerView
        }

        NSLayoutConstraint.activate([
            contentStackView.widthAnchor.constraint(equalToConstant: preferredWidth),
            contentStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func configureDismissalViewIfNeeded() {
        guard let dismissalImageView = dismissalImageView else {
            return
        }

        dismissalImageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        dismissalImageView.addGestureRecognizer(tapGestureRecognizer)

        addSubview(dismissalImageView)

        let screenBounds = UIScreen.main.bounds
        let horizontalDismissalInset = screenBounds.width * Parameters.dismissalInsetScaleFactor
        let verticalDismissalInset = screenBounds.height * Parameters.dismissalInsetScaleFactor

        NSLayoutConstraint.activate([
            dismissalImageView.widthAnchor.constraint(equalToConstant: Parameters.dismissalDimension),
            dismissalImageView.heightAnchor.constraint(equalToConstant: Parameters.dismissalDimension),
            dismissalImageView.topAnchor.constraint(equalTo: topAnchor, constant: verticalDismissalInset),
            dismissalImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalDismissalInset)
        ])
    }

    private func configureSupportLabelIfNeeded() {
        guard let contactSupportLabel = contactSupportLabel else {
            return
        }

        contactSupportLabel.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(contactSupportTapped))
        contactSupportLabel.addGestureRecognizer(tapGestureRecognizer)

        addSubview(contactSupportLabel)

        NSLayoutConstraint.activate([
            contactSupportLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            contactSupportLabel.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: Parameters.supportTopInset)
        ])
    }
}

// MARK: ErrorStateView support

@objc
private extension ErrorStateView {
    @objc func contactSupportTapped() {
        configuration.contactSupportActionHandler?()
    }

    @objc func dismissTapped() {
        configuration.dismissalActionHandler?()
    }

    @objc func retryTapped() {
        configuration.retryActionHandler?()
    }
}
