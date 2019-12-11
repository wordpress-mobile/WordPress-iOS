import UIKit
import Gridicons

class SiteCreationRotatingMessageView: UIView {
    private struct Margins {
        static let horizontalMargin: CGFloat = 0
        static let verticalMargin: CGFloat = 0

        static let horizontalSpacing: CGFloat = 15
    }

    private struct Parameters {
        //Animation parameters
        static let transitionAnimationDuration = TimeInterval(0.5)
        private static let statusDisplayDuration = TimeInterval(2)

        //Adjust the total display time to take the fade into consideration
        static var totalStatusDisplayDuration: TimeInterval {
            return statusDisplayDuration + transitionAnimationDuration
        }

        //Checkmark configuration
        static let checkmarkImageSize = CGSize(width: 18, height: 18)
        static let checkmarkImageColor = UIColor.muriel(color: .success, .shade20)
    }

    private let statusMessages = [
        "Grabbing site URL",
        "Adding site features",
        "Setting up theme",
        "Creating dashboard"
    ]

    // MARK: - State Management
    private var animationTimer: Timer!
    private var visibleIndex = 0
    private var nextVisibleIndex: Int {
        get {
            var nextIndex = visibleIndex + 1
            if nextIndex >= statusMessages.count {
                nextIndex = 0
            }

            return nextIndex
        }
    }

    // MARK: - View Properties
    private(set) var statusLabel: UILabel = {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false

        label.font = WPStyleGuide.fontForTextStyle(.title2)
        label.textColor = .textSubtle
        label.textAlignment = .center

        return label
    }()

    /// The stack view manages the appearance of a status label and a loading indicator.
    private let statusStackView: UIStackView = {
        let stackView = UIStackView()

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.spacing = Margins.horizontalSpacing

        return stackView
    }()

    private let statusImageView: UIImageView = {
        let icon = Gridicon.iconOfType(.checkmark, withSize: Parameters.checkmarkImageSize)
        let imageView = UIImageView(image: icon)

        imageView.tintColor = Parameters.checkmarkImageColor

        return imageView
    }()

    // MARK: - UIView
    override init(frame: CGRect) {
        super.init(frame: frame)

        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        configure()
    }

    // MARK: - Public Methods
    func startAnimating() {
        stopAnimating()

        self.animationTimer = Timer.scheduledTimer(timeInterval: Parameters.totalStatusDisplayDuration,
                                                   target: self,
                                                   selector: #selector(SiteCreationRotatingMessageView.displayNextMessage),
                                                   userInfo: nil,
                                                   repeats: true)
    }


    /// Cancels the timer, and stops the rotating animations
    func stopAnimating() {
        guard let timer = animationTimer else {
            return
        }

        timer.invalidate()
        animationTimer = nil

        reset()
    }

    // MARK: - Private

    /// Configures the stackview, and sets some contraints
    private func configure() {
        reset()

        translatesAutoresizingMaskIntoConstraints = false

        statusStackView.addArrangedSubviews([ statusImageView, statusLabel ])

        addSubview(statusStackView)

        NSLayoutConstraint.activate([
            statusStackView.topAnchor.constraint(equalTo: topAnchor, constant: Margins.verticalMargin),
            statusStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Margins.horizontalMargin),
            statusStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Margins.horizontalMargin),
            statusStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Margins.verticalMargin),

        ])
    }

    /// Resets the visible index to 0, and changes the visible message to the first one
    private func reset() {
        visibleIndex = 0

        //Update the status label with the first status message in the list
        statusLabel.text = statusMessages[0]
    }

    /// Fades the current message out, updates the status label to the next message
    /// then fades the message view back in
    @objc private func displayNextMessage() {
        let transitionDuration = Parameters.transitionAnimationDuration

        let updateStatusText = {
            let nextIndex = self.nextVisibleIndex
            let statusMessage = self.statusMessages[nextIndex]

            self.updateStatus(message: statusMessage);

            self.visibleIndex = nextIndex
        }

        let fadeIn = {
            UIView.animate(withDuration: transitionDuration) {
                self.statusStackView.alpha = 1
            }
        }

        //Fade the stackview out, then update the status text, then fade in back in
        UIView.animate(withDuration: transitionDuration, animations: {
            self.statusStackView.alpha = 0
        }, completion: { _ in
            updateStatusText()

            fadeIn()
        })
    }

    /// Updates the status label/accessiblity label with the provided text
    /// - Parameter message: The text to be displayed
    private func updateStatus(message: String) {
        let statusMessage = NSLocalizedString(message,
                                              comment: "User-facing string, presented to reflect that site assembly is underway.")

        self.statusLabel.text = statusMessage
        self.statusLabel.accessibilityLabel = statusMessage

    }


}
