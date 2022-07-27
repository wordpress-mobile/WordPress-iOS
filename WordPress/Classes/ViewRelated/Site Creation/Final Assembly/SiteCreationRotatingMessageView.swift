import UIKit

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
    }
    /// An array of status messages to rotating through
    private(set) var statusMessages: [String]

    // MARK: - State Management

    /// A timer that determines how long to show each message
    private(set) var animationTimer: Timer?

    /// The index of the currently visible message
    private(set) var visibleIndex = 0

    /// Calculates the index that should be displayed next,
    /// This will automatically loop back to 0 if we hit the end
    internal var nextVisibleIndex: Int {
        get {
            var nextIndex = visibleIndex + 1
            if nextIndex >= statusMessages.count {
                nextIndex = 0
            }

            return nextIndex
        }
    }

    // MARK: - View Properties

    /// The icon that is displayed next to the status view
    private var statusImageView: UIImageView

    /// This advises the user that the site creation request is underway.
    private(set) var statusLabel: UILabel = {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false

        label.font = WPStyleGuide.fontForTextStyle(.title2)
        label.textColor = .textSubtle
        label.textAlignment = .center

        return label
    }()

    /// The stack view manages the appearance of a icon image, and a status label
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

    // MARK: - UIView

    /// Creates a new instance of the message view with the provided messages
    /// - Parameter messages: An array of messages to display
    /// - Parameter iconImage: The icon image to display before the status message
    init(messages: [String], iconImage: UIImage) {
        self.statusMessages = messages
        self.statusImageView = UIImageView(image: iconImage)

        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods
    func startAnimating() {
        stopAnimating()

        animationTimer = Timer.scheduledTimer(timeInterval: Parameters.totalStatusDisplayDuration,
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

    // MARK: - Internal
    /// Resets the visible index to 0, and changes the visible message to the first one
    internal func reset() {
        visibleIndex = 0

        //Update the status label with the first status message in the list
        statusLabel.text = statusMessages[0]
    }

    /// Updates the status label text with the next message to be displayed
    /// then updates the current visible index
    internal func updateStatusLabelWithNextMessage() {
        let nextIndex = nextVisibleIndex
        let statusMessage = statusMessages[nextIndex]

        updateStatus(message: statusMessage)

        visibleIndex = nextIndex
    }

    /// Updates the status label/accessiblity label with the provided text
    /// - Parameter message: The text to be displayed
    internal func updateStatus(message: String) {
        statusLabel.text = message
    }

    // MARK: - Private

    /// Configures the stackview, and sets the view constraints
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

    /// Fades the current message out, updates the status label to the next message
    /// then fades the message view back in
    @objc private func displayNextMessage() {
        let transitionDuration = Parameters.transitionAnimationDuration

        let fadeIn = {
            UIView.animate(withDuration: transitionDuration) {
                self.statusStackView.alpha = 1
            }
        }

        //Fade the stackview out, then update the status text, then fade in back in
        UIView.animate(withDuration: transitionDuration, animations: {
            self.statusStackView.alpha = 0
        }, completion: { _ in
            self.updateStatusLabelWithNextMessage()

            fadeIn()
        })
    }
}
