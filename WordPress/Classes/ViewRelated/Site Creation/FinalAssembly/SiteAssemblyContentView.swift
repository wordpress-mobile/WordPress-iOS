
import UIKit

// MARK: SiteAssemblyContentView

/// This view is intended for use as the root view of `SiteAssemblyWizardContent`.
/// It manages the state transitions that occur as a site is assembled via remote service dialogue.
///
final class SiteAssemblyContentView: UIView {

    // MARK: Properties

    private struct Parameters {
        static let animationDuration                            = TimeInterval(0.5)
        static let assembledSiteScaleFactorWidth                = CGFloat(0.79)
        static let assembledSiteScaleFactorHeight               = CGFloat(0.79)
        static let buttonContainerScaleFactor                   = CGFloat(2)
        static let completionLabelHorizontalInset               = CGFloat(37)
        static let labelSpacingScaleFactor                      = CGFloat(0.032)
        static let statusStackViewSpacing                       = CGFloat(16)
    }

    private var completionLabelTopConstraint: NSLayoutConstraint?

    private(set) var completionLabel: UILabel

    private let statusLabel: UILabel

    private let activityIndicator: UIActivityIndicatorView

    private(set) var statusStackView: UIStackView

    private var assembledSiteTopConstraint: NSLayoutConstraint?

    private(set) var assembledSiteView: AssembledSiteView?

    private var buttonContainerBottomConstraint: NSLayoutConstraint?

    private var buttonContainerContainer: UIView?

    var buttonContainerView: UIView? {
        didSet {
            installButtonContainerView()
        }
    }

    var domainName: String? {
        didSet {
            installAssembledSiteView()
        }
    }

    var status: SiteAssemblyStatus = .idle {
        didSet {
            setNeedsLayout()
        }
    }

    // MARK: SiteAssemblyContentView

    init() {
        self.completionLabel = {
            let label = UILabel()

            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0

            label.font = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .bold)
            label.textColor = WPStyleGuide.darkGrey()
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
            label.textColor = WPStyleGuide.greyDarken10()
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
            activityIndicator.color = WPStyleGuide.greyDarken10()
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
            assembledSiteView?.urlString = "https://longreads.com"
            layoutSucceeded()
        }
    }

    // MARK: Private behavior

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [ .flexibleWidth, .flexibleHeight ]

        backgroundColor = WPStyleGuide.greyLighten30()

        statusStackView.addArrangedSubviews([ statusLabel, activityIndicator ])
        addSubviews([ completionLabel, statusStackView ])

        let screenHeight = UIScreen.main.bounds.height
        let completionLabelTopInsetInitial = screenHeight * (Parameters.labelSpacingScaleFactor * 2)
        let completionLabelInitialTopConstraint = completionLabel.topAnchor.constraint(equalTo: prevailingLayoutGuide.topAnchor, constant: completionLabelTopInsetInitial)
        self.completionLabelTopConstraint = completionLabelInitialTopConstraint

        NSLayoutConstraint.activate([
            completionLabelInitialTopConstraint,
            completionLabel.leadingAnchor.constraint(equalTo: prevailingLayoutGuide.leadingAnchor, constant: Parameters.completionLabelHorizontalInset),
            completionLabel.trailingAnchor.constraint(equalTo: prevailingLayoutGuide.trailingAnchor, constant: -Parameters.completionLabelHorizontalInset),
            completionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusStackView.leadingAnchor.constraint(equalTo: prevailingLayoutGuide.leadingAnchor, constant: Parameters.completionLabelHorizontalInset),
            statusStackView.trailingAnchor.constraint(equalTo: prevailingLayoutGuide.trailingAnchor, constant: -Parameters.completionLabelHorizontalInset),
            statusStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func installAssembledSiteView() {
        guard let domainName = domainName else {
            return
        }

        let assembledSiteView = AssembledSiteView(domainName: domainName)
        addSubview(assembledSiteView)

        if let buttonContainer = buttonContainerContainer {
            bringSubviewToFront(buttonContainer)
        }

        let initialSiteTopConstraint = assembledSiteView.topAnchor.constraint(equalTo: bottomAnchor)
        self.assembledSiteTopConstraint = initialSiteTopConstraint

        let screenHeight = UIScreen.main.bounds.height
        let assembledSiteTopInset = screenHeight * Parameters.labelSpacingScaleFactor

        NSLayoutConstraint.activate([
            initialSiteTopConstraint,
            assembledSiteView.topAnchor.constraint(greaterThanOrEqualTo: completionLabel.bottomAnchor, constant: assembledSiteTopInset),
            assembledSiteView.centerXAnchor.constraint(equalTo: centerXAnchor),
            assembledSiteView.widthAnchor.constraint(equalTo: prevailingLayoutGuide.widthAnchor, multiplier: Parameters.assembledSiteScaleFactorWidth),
            assembledSiteView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: Parameters.assembledSiteScaleFactorHeight)
        ])

        self.assembledSiteView = assembledSiteView
    }

    private func installButtonContainerView() {
        guard let buttonContainerView = buttonContainerView else {
            return
        }

        // This wrapper view provides underlap for Home indicator
        let buttonContainerContainer = UIView(frame: .zero)
        buttonContainerContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainerContainer.backgroundColor = .white
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
            buttonContainerContainer.leadingAnchor.constraint(equalTo: prevailingLayoutGuide.leadingAnchor),
            buttonContainerContainer.trailingAnchor.constraint(equalTo: prevailingLayoutGuide.trailingAnchor),
            bottomConstraint,
        ])
    }

    private func layoutIdle() {
        completionLabel.alpha = 0
        statusStackView.alpha = 0
    }

    private func layoutInProgress() {
        UIView.animate(withDuration: Parameters.animationDuration, delay: 0, options: .curveEaseOut, animations: { [statusStackView] in

            statusStackView.alpha = 1
        })
    }

    private func layoutFailed() {
        debugPrint(#function)
    }

    private func layoutSucceeded() {
        UIView.animate(withDuration: Parameters.animationDuration, delay: 0, options: .curveEaseOut, animations: { [statusStackView] in

            statusStackView.alpha = 0

            }, completion: { [weak self] completed in

                guard completed, let strongSelf = self else {
                    return
                }

                let screenHeight = UIScreen.main.bounds.height
                let completionLabelTopInsetFinal = screenHeight * Parameters.labelSpacingScaleFactor
                strongSelf.completionLabelTopConstraint?.constant = completionLabelTopInsetFinal

                let siteHeight = strongSelf.assembledSiteView?.bounds.height ?? 0
                strongSelf.assembledSiteTopConstraint?.constant = -siteHeight

                strongSelf.buttonContainerBottomConstraint?.constant = 0

                UIView.animate(withDuration: Parameters.animationDuration,
                               delay: 0,
                               options: .curveEaseOut,
                               animations: { [weak self] in
                                guard let strongSelf = self else {
                                    return
                                }

                                strongSelf.completionLabel.alpha = 1
                                strongSelf.layoutIfNeeded()
                })
        })
    }
}
