import Foundation
import UIKit
import Gridicons
import WordPressShared

// MARK: SiteAssemblyContentView

/// This view is intended for use as the root view of `SiteAssemblyWizardContent`.
/// It manages the state transitions that occur as a site is assembled via remote service dialogue.
final class SiteAssemblyContentView: UIView {

    // MARK: Properties

    /// A collection of parameters uses for animation & layout of the view.
    private struct Parameters {
        static let animationDuration                        = TimeInterval(0.5)
        static let buttonContainerScaleFactor               = CGFloat(2)
        static let horizontalMargin                         = CGFloat(30)
        static let verticalSpacing                          = CGFloat(30)
        static let statusStackViewSpacing                   = CGFloat(16)
        static let checkmarkImageSize                       = CGSize(width: 18, height: 18)
        static let checkmarkImageColor                      = UIColor.muriel(color: .success, .shade20)
    }

    /// This influences the top of the completion label as it animates into place.
    private var completionLabelTopConstraint: NSLayoutConstraint?

    /// This advises the user that the site creation request completed successfully.
    private(set) var completionLabel: UILabel

    private let completionDescription: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.numberOfLines = 0
        $0.font = WPStyleGuide.fontForTextStyle(.body)
        $0.textColor = .text
        return $0
    }(UILabel())

    private let noticeView: UIView = {
        let noticeText = NSLocalizedString(
            "domain.purchase.preview.footer",
            value: "It may take up to 30 minutes for your custom domain to start working.",
            comment: "Domain Purchase Completion footer"
        )
        let noticeView = DomainSetupNoticeView(noticeText: noticeText)
        let embeddedView = UIView.embedSwiftUIView(noticeView)
        embeddedView.translatesAutoresizingMaskIntoConstraints = false
        return embeddedView
    }()

    private lazy var completionLabelsStack: UIStackView = {
        $0.addArrangedSubviews([completionLabel, completionDescription, noticeView])
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.spacing = 24
        return $0
    }(UIStackView())

    /// This provides the user with some playful words while their site is being assembled
    private let statusTitleLabel: UILabel

    /// This provides the user with some expectation while the site is being assembled
    private let statusSubtitleLabel: UILabel

    /// This displays an image while the site is being assembled
    private let statusImageView: UIImageView

    /// This advises the user that the site creation request is underway.
    private let statusMessageRotatingView: SiteCreationRotatingMessageView

    /// The loading indicator provides an indeterminate view of progress as the site is being created.
    private let activityIndicator: UIActivityIndicatorView

    /// The stack view manages the appearance of a status label and a loading indicator.
    private(set) var statusStackView: UIStackView

    /// This influences the top of the assembled site, which varies by device & orientation.
    private var assembledSiteTopConstraint: NSLayoutConstraint?

    /// This influences the width of the assembled site, which varies by device & orientation.
    private var assembledSiteWidthConstraint: NSLayoutConstraint?

    /// This is a representation of the assembled site.
    private(set) var assembledSiteView: AssembledSiteView?

    /// This constraint influences the presentation of the Done button as it animates into view.
    private var buttonContainerBottomConstraint: NSLayoutConstraint?

    /// We adjust the button container view slightly to account for the Home indicator ("unsafe") region on the device.
    private var buttonContainerContainer: UIView?

    /// The button container view is associated with the root view of a `NUXButtonViewController`
    var buttonContainerView: UIView? {
        didSet {
            installButtonContainerView()
        }
    }

    /// The view apprising the user of an error encountering during the site assembly attempt.
    var errorStateView: UIView? {
        didSet {
            installErrorStateView()
        }
    }

    /// The full address of the created site.
    var siteURLString: String?

    /// The domain name is applied to the appearance of the created site.
    var siteName: String? {
        didSet {
            installAssembledSiteView()
        }
    }

    /// The status of site assembly. As the state advances, the view updates in concert.
    var status: SiteAssemblyStatus = .idle {
        // Start and stop the message rotation
        willSet {
            switch newValue {
            case .inProgress:
                statusMessageRotatingView.startAnimating()

            default:
                statusMessageRotatingView.stopAnimating()
            }
        }

        didSet {
            setNeedsLayout()
        }
    }

    let siteCreator: SiteCreator

    var isFreeDomain: Bool?
    private func shouldShowDomainPurchase() -> Bool {
        if let isFreeDomain = isFreeDomain {
            return !isFreeDomain
        }
        return siteCreator.shouldShowCheckout
    }

    // MARK: SiteAssemblyContentView

    /// The designated initializer.
    init(siteCreator: SiteCreator) {
        self.siteCreator = siteCreator

        self.completionLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0

            label.font = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .bold)
            label.textColor = .text

            if siteCreator.domainPurchasingEnabled {
                label.textAlignment = .natural
            } else {
                label.textAlignment = .center
            }

            label.text = Strings.Free.completionTitle
            label.accessibilityLabel = Strings.Free.completionTitle

            return label
        }()

        self.statusTitleLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0

            label.font = WPStyleGuide.fontForTextStyle(.largeTitle, fontWeight: .bold)
            label.textColor = .text
            label.textAlignment = .center

            let statusText = NSLocalizedString("Hooray!\nAlmost done",
                                               comment: "User-facing string, presented to reflect that site assembly is underway.")
            label.text = statusText
            label.accessibilityLabel = statusText

            return label
        }()

        self.statusSubtitleLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0

            label.font = WPStyleGuide.fontForTextStyle(.title2)
            label.textColor = .textSubtle
            label.textAlignment = .center

            let statusText = NSLocalizedString("Your site will be ready shortly",
                                               comment: "User-facing string, presented to reflect that site assembly is underway.")
            label.text = statusText
            label.accessibilityLabel = statusText

            return label
        }()

        self.statusImageView = {
            let image = UIImage(named: "site-creation-loading")
            let imageView = UIImageView(image: image)

            return imageView
        }()

        self.statusMessageRotatingView = {
            //The rotating message view will automatically use the localized string based
            //on the message

            let statusMessages = [
                NSLocalizedString("Grabbing site URL",
                                  comment: "User-facing string, presented to reflect that site assembly is underway."),

                NSLocalizedString("Adding site features",
                                  comment: "User-facing string, presented to reflect that site assembly is underway."),

                NSLocalizedString("Setting up theme",
                                  comment: "User-facing string, presented to reflect that site assembly is underway."),

                NSLocalizedString("Creating dashboard",
                                  comment: "User-facing string, presented to reflect that site assembly is underway."),
            ]

            let icon: UIImage = {
                let iconSize = Parameters.checkmarkImageSize
                let tintColor = Parameters.checkmarkImageColor
                let icon = UIImage.gridicon(.checkmark, size: iconSize)

                guard let tintedIcon = icon.imageWithTintColor(tintColor) else {
                    return icon
                }

                return tintedIcon
            }()

            return SiteCreationRotatingMessageView(messages: statusMessages, iconImage: icon)
        }()

        self.activityIndicator = {
            let activityIndicator = UIActivityIndicatorView(style: .large)

            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.hidesWhenStopped = true
            activityIndicator.color = .textSubtle
            activityIndicator.startAnimating()

            return activityIndicator
        }()

        self.statusStackView = {
            let stackView = UIStackView()

            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.alignment = .center
            stackView.axis = .vertical
            stackView.spacing = Parameters.statusStackViewSpacing

            return stackView
        }()

        super.init(frame: .zero)

        configure()
    }

    /// This method is intended to be called by its owning view controller when constraints change.
    func adjustConstraints() {
        guard let assembledSitePreferredSize = assembledSiteView?.preferredSize,
            let widthConstraint = assembledSiteWidthConstraint else {

            return
        }

        widthConstraint.constant = assembledSitePreferredSize.width
        layoutIfNeeded()
    }

    // MARK: UIView

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        switch status {
        case .idle:
            layoutIdle()
        case .inProgress:
            layoutInProgress()
        case .failed:
            layoutFailed()
        case .succeeded:
            layoutSucceeded()
        }
    }

    // MARK: Private behavior

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [ .flexibleWidth, .flexibleHeight ]

        backgroundColor = .listBackground

        statusStackView.addArrangedSubviews([ statusTitleLabel, statusSubtitleLabel, statusImageView, statusMessageRotatingView, activityIndicator ])
        addSubviews([completionLabelsStack, statusStackView])

        // Increase the spacing around the illustration
        statusStackView.setCustomSpacing(Parameters.verticalSpacing, after: statusSubtitleLabel)
        statusStackView.setCustomSpacing(Parameters.verticalSpacing, after: statusImageView)

        let completionLabelTopInsetInitial = Parameters.verticalSpacing * 2
        let completionLabelInitialTopConstraint = completionLabelsStack.topAnchor.constraint(equalTo: prevailingLayoutGuide.topAnchor, constant: completionLabelTopInsetInitial)
        self.completionLabelTopConstraint = completionLabelInitialTopConstraint

        NSLayoutConstraint.activate([
            completionLabelInitialTopConstraint,
            completionLabelsStack.leadingAnchor.constraint(equalTo: prevailingLayoutGuide.leadingAnchor, constant: Parameters.horizontalMargin),
            prevailingLayoutGuide.trailingAnchor.constraint(equalTo: completionLabelsStack.trailingAnchor, constant: Parameters.horizontalMargin),
            completionLabelsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusStackView.leadingAnchor.constraint(equalTo: prevailingLayoutGuide.leadingAnchor, constant: Parameters.horizontalMargin),
            prevailingLayoutGuide.trailingAnchor.constraint(equalTo: statusStackView.trailingAnchor, constant: Parameters.horizontalMargin),
            statusStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            noticeView.leadingAnchor.constraint(equalTo: completionLabelsStack.leadingAnchor),
            completionLabelsStack.trailingAnchor.constraint(equalTo: noticeView.trailingAnchor)
        ])
    }

    private func installAssembledSiteView() {
        guard let siteName = siteName, let siteURLString = siteURLString else {
            return
        }

        if let assembledSiteView {
            assembledSiteView.removeFromSuperview()
        }

        let assembledSiteView = AssembledSiteView(domainName: siteName, siteURLString: siteURLString, siteCreator: siteCreator)
        addSubview(assembledSiteView)

        if let buttonContainer = buttonContainerContainer {
            bringSubviewToFront(buttonContainer)
        }

        let initialSiteTopConstraint = assembledSiteView.topAnchor.constraint(equalTo: bottomAnchor)
        self.assembledSiteTopConstraint = initialSiteTopConstraint

        let assembledSiteTopInset = Parameters.verticalSpacing

        let preferredAssembledSiteSize = assembledSiteView.preferredSize

        let assembledSiteWidthConstraint = assembledSiteView.widthAnchor.constraint(equalToConstant: preferredAssembledSiteSize.width)
        self.assembledSiteWidthConstraint = assembledSiteWidthConstraint

        let assembledSiteViewBottomConstraint: NSLayoutConstraint
        if shouldShowDomainPurchase() {
            assembledSiteView.layer.cornerRadius = 12
            assembledSiteView.layer.masksToBounds = true
            assembledSiteViewBottomConstraint = (buttonContainerView?.topAnchor ?? bottomAnchor).constraint(
                equalTo: assembledSiteView.bottomAnchor,
                constant: 24
            )

            completionLabel.text = Strings.Paid.completionTitle
            completionLabel.accessibilityLabel = Strings.Paid.completionTitle
            completionDescription.text = Strings.Paid.description
        } else {
            assembledSiteViewBottomConstraint = assembledSiteView.bottomAnchor.constraint(
                equalTo: buttonContainerView?.topAnchor ?? bottomAnchor
            )
            completionDescription.text = Strings.Free.description
        }

        NSLayoutConstraint.activate([
            initialSiteTopConstraint,
            assembledSiteView.topAnchor.constraint(greaterThanOrEqualTo: completionLabelsStack.bottomAnchor, constant: assembledSiteTopInset),
            assembledSiteViewBottomConstraint,
            assembledSiteView.centerXAnchor.constraint(equalTo: centerXAnchor),
            assembledSiteWidthConstraint,
            (buttonContainerView?.topAnchor ?? bottomAnchor).constraint(equalTo: assembledSiteView.bottomAnchor, constant: 15)
        ])

        self.assembledSiteView = assembledSiteView
    }

    private func installButtonContainerView() {
        guard let buttonContainerView = buttonContainerView else {
            return
        }

        buttonContainerView.backgroundColor = .basicBackground

        // This wrapper view provides underlap for Home indicator
        let buttonContainerContainer = UIView(frame: .zero)
        buttonContainerContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainerContainer.backgroundColor = .basicBackground
        buttonContainerContainer.addSubview(buttonContainerView)
        addSubview(buttonContainerContainer)
        self.buttonContainerContainer = buttonContainerContainer

        let buttonContainerHeight = buttonContainerView.bounds.height
        let safelyOffscreen = Parameters.buttonContainerScaleFactor * buttonContainerHeight
        let bottomConstraint = buttonContainerView.bottomAnchor.constraint(equalTo: prevailingLayoutGuide.bottomAnchor, constant: safelyOffscreen)
        self.buttonContainerBottomConstraint = bottomConstraint

        NSLayoutConstraint.activate([
            buttonContainerView.topAnchor.constraint(equalTo: buttonContainerContainer.topAnchor),
            buttonContainerView.leadingAnchor.constraint(equalTo: buttonContainerContainer.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: buttonContainerContainer.trailingAnchor),
            buttonContainerContainer.heightAnchor.constraint(equalTo: buttonContainerView.heightAnchor, multiplier: Parameters.buttonContainerScaleFactor),
            buttonContainerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonContainerContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomConstraint,
        ])
    }

    private func installErrorStateView() {
        guard let errorStateView = errorStateView else {
            return
        }

        errorStateView.alpha = 0
        addSubview(errorStateView)

        NSLayoutConstraint.activate([
            errorStateView.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorStateView.trailingAnchor.constraint(equalTo: trailingAnchor),
            errorStateView.topAnchor.constraint(equalTo: topAnchor),
            errorStateView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func layoutIdle() {
        completionLabel.isHidden = true
        completionDescription.isHidden = true
        noticeView.isHidden = true
        statusStackView.alpha = 0
        errorStateView?.alpha = 0
    }

    private func layoutInProgress() {
        UIView.animate(withDuration: Parameters.animationDuration, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            guard let self = self else {
                return
            }
            self.errorStateView?.alpha = 0
            self.statusStackView.alpha = 1
            self.accessibilityElements = [ self.statusMessageRotatingView.statusLabel ]
        })
    }

    private func layoutFailed() {
        UIView.animate(withDuration: Parameters.animationDuration, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            guard let self = self else {
                return
            }

            self.statusStackView.alpha = 0

            if let errorView = self.errorStateView {
                errorView.alpha = 1
                self.accessibilityElements = [ errorView ]
            }
        })
    }

    private func layoutSucceeded() {
        assembledSiteView?.loadSiteIfNeeded()

        UIView.animate(withDuration: Parameters.animationDuration, delay: 0, options: .curveEaseOut, animations: { [statusStackView] in
            statusStackView.alpha = 0
            }, completion: { [weak self] completed in
                guard completed, let self = self else {
                    return
                }

                let completionLabelTopInsetFinal = Parameters.verticalSpacing
                self.completionLabelTopConstraint?.constant = completionLabelTopInsetFinal

                self.assembledSiteTopConstraint?.isActive = false
                let transitionConstraint = self.assembledSiteView?.topAnchor.constraint(
                    equalTo: self.completionLabelsStack.bottomAnchor,
                    constant: Parameters.verticalSpacing
                )
                transitionConstraint?.isActive = true
                self.assembledSiteTopConstraint = transitionConstraint

                self.buttonContainerBottomConstraint?.constant = 0

                UIView.animate(withDuration: Parameters.animationDuration,
                               delay: 0,
                               options: .curveEaseOut,
                               animations: { [weak self] in
                    guard let self = self else {
                        return
                    }

                    self.completionLabel.isHidden = false
                    self.completionDescription.isHidden = false
                    self.completionLabel.text = self.shouldShowDomainPurchase() ? Strings.Paid.completionTitle : Strings.Free.completionTitle
                    self.completionDescription.text = self.shouldShowDomainPurchase() ? Strings.Paid.description : Strings.Free.description
                    self.noticeView.isHidden = !self.shouldShowDomainPurchase()


                    if let buttonView = self.buttonContainerView {
                        self.accessibilityElements = [ self.completionLabel, buttonView ]
                    } else {
                        self.accessibilityElements = [ self.completionLabel ]
                    }

                    self.layoutIfNeeded()
                })
            })
    }
}

private enum Strings {
    enum Paid {
        static let completionTitle = NSLocalizedString(
            "domain.purchase.preview.title",
            value: "Kudos, your site is live!",
            comment: "Reflects that site is live when domain purchase feature flag is ON."
        )

        static let description = NSLocalizedString(
            "domain.purchase.preview.paid.description",
            value: "We’ve emailed your receipt. Next, we'll help you get it ready for everyone.",
            comment: "Domain Purchase Completion description (only for PAID domains)."
        )
    }

    enum Free {
        static let completionTitle = NSLocalizedString(
            "Your site has been created!",
            comment: "User-facing string, presented to reflect that site assembly completed successfully."
        )
        static let description = NSLocalizedString(
            "domain.purchase.preview.free.description",
            value: "Next, we'll help you get it ready to be browsed.",
            comment: "Domain Purchase Completion description (only for FREE domains)."
        )

    }
}
