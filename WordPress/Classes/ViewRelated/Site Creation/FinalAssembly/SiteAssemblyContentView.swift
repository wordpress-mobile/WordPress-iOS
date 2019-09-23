
import UIKit

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
    }

    /// This influences the top of the completion label as it animates into place.
    private var completionLabelTopConstraint: NSLayoutConstraint?

    /// This advises the user that the site creation request completed successfully.
    private(set) var completionLabel: UILabel

    /// This advises the user that the site creation request is underway.
    private let statusLabel: UILabel

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
        didSet {
            setNeedsLayout()
        }
    }

    // MARK: SiteAssemblyContentView

    /// The designated initializer.
    init() {
        self.completionLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0

            label.font = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .bold)
            label.textColor = .text
            label.textAlignment = .center

            let createdText = NSLocalizedString("Your site has been created!",
                                              comment: "User-facing string, presented to reflect that site assembly completed successfully.")
            label.text = createdText
            label.accessibilityLabel = createdText

            return label
        }()

        self.statusLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0

            label.font = WPStyleGuide.fontForTextStyle(.title2)
            label.textColor = .textSubtle
            label.textAlignment = .center

            let statusText = NSLocalizedString("We’re creating your new site.",
                                               comment: "User-facing string, presented to reflect that site assembly is underway.")
            label.text = statusText
            label.accessibilityLabel = statusText

            return label
        }()

        self.activityIndicator = {
            let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)

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

        statusStackView.addArrangedSubviews([ statusLabel, activityIndicator ])
        addSubviews([ completionLabel, statusStackView ])

        let completionLabelTopInsetInitial = Parameters.verticalSpacing * 2
        let completionLabelInitialTopConstraint = completionLabel.topAnchor.constraint(equalTo: prevailingLayoutGuide.topAnchor, constant: completionLabelTopInsetInitial)
        self.completionLabelTopConstraint = completionLabelInitialTopConstraint

        NSLayoutConstraint.activate([
            completionLabelInitialTopConstraint,
            completionLabel.leadingAnchor.constraint(equalTo: prevailingLayoutGuide.leadingAnchor, constant: Parameters.horizontalMargin),
            completionLabel.trailingAnchor.constraint(equalTo: prevailingLayoutGuide.trailingAnchor, constant: -Parameters.horizontalMargin),
            completionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusStackView.leadingAnchor.constraint(equalTo: prevailingLayoutGuide.leadingAnchor, constant: Parameters.horizontalMargin),
            statusStackView.trailingAnchor.constraint(equalTo: prevailingLayoutGuide.trailingAnchor, constant: -Parameters.horizontalMargin),
            statusStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func installAssembledSiteView() {
        guard let siteName = siteName, let siteURLString = siteURLString else {
            return
        }

        let assembledSiteView = AssembledSiteView(domainName: siteName, siteURLString: siteURLString)
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

        NSLayoutConstraint.activate([
            initialSiteTopConstraint,
            assembledSiteView.topAnchor.constraint(greaterThanOrEqualTo: completionLabel.bottomAnchor, constant: assembledSiteTopInset),
            assembledSiteView.bottomAnchor.constraint(equalTo: buttonContainerView?.topAnchor ?? bottomAnchor),
            assembledSiteView.centerXAnchor.constraint(equalTo: centerXAnchor),
            assembledSiteWidthConstraint,
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
        completionLabel.alpha = 0
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
            self.accessibilityElements = [ self.statusLabel ]
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
                let transitionConstraint = self.assembledSiteView?.topAnchor.constraint(equalTo: self.completionLabel.bottomAnchor, constant: Parameters.verticalSpacing)
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

                                self.completionLabel.alpha = 1

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
