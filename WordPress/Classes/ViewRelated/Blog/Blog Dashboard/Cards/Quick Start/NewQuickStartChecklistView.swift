import UIKit

// A view representing the progress on a Quick Start checklist. Built according to new design specs.
//
// This view is used to display a single Quick Start tour collection per Quick Start card.
//
// This view can be renamed to QuickStartChecklistView once we've fully migrated to using this new view.
// See QuickStartChecklistConfigurable for more details.
//
final class NewQuickStartChecklistView: UIView, QuickStartChecklistConfigurable {

    var tours: [QuickStartTour] = []
    var blog: Blog?
    var onTap: (() -> Void)?

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            verticalStackView,
            imageView
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .equalSpacing
        return stackView
    }()

    private lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            progressStackView
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.serifFontForTextStyle(.title2, fontWeight: .semibold)
        label.textColor = .text
        label.numberOfLines = 0
        return label
    }()

    private lazy var progressStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            subtitleStackView,
            progressView
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.progressStackViewSpacing
        return stackView
    }()

    private lazy var subtitleStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            subtitleLabel,
            checkmarkIcon
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.fontForTextStyle(.subheadline)
        label.textColor = .textSubtle
        return label
    }()

    private lazy var checkmarkIcon: UIImageView = {
        let imageView = UIImageView(image: .gridicon(.checkmark, size: Metrics.checkmarkIconSize))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = Colors.allTasksComplete
        return imageView
    }()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .primary
        progressView.trackTintColor = Colors.progressViewTrackTint
        progressView.layer.cornerRadius = Metrics.progressViewHeight / 2
        progressView.clipsToBounds = true
        return progressView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "wp-illustration-quickstart-existing-site"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        startObservingQuickStart()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    deinit {
        stopObservingQuickStart()
    }

    // MARK: - Trait Collection

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureVerticalStackViewSpacing()
    }

    private func configureVerticalStackViewSpacing() {
        if UIDevice.current.orientation.isLandscape {
            verticalStackView.spacing = Metrics.verticalStackViewSpacingLandscape
        } else {
            verticalStackView.spacing = Metrics.verticalStackViewSpacingPortrait
        }
    }

    // MARK: - Configure

    func configure(collection: QuickStartToursCollection, blog: Blog) {
        self.tours = collection.tours
        self.blog = blog
        titleLabel.text = collection.title

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityHint = collection.hint

        updateViews()
    }
}

extension NewQuickStartChecklistView {

    private func setupViews() {
        configureVerticalStackViewSpacing()

        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView, insets: Metrics.mainStackViewInsets)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Metrics.imageWidth),
            imageView.heightAnchor.constraint(equalToConstant: Metrics.imageHeight),
            progressView.heightAnchor.constraint(equalToConstant: Metrics.progressViewHeight),
            verticalStackView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: Metrics.verticalStackViewWidthMultiplier),
        ])
    }

    private func updateViews() {
        guard let blog = blog,
            let title = titleLabel.text else {
            return
        }

        let completedToursCount = QuickStartTourGuide.shared.countChecklistCompleted(in: tours, for: blog)

        var subtitle: String

        if completedToursCount == tours.count {
            subtitle = Strings.allTasksComplete
            progressView.progressTintColor = Colors.allTasksComplete
            checkmarkIcon.isHidden = false
        } else {
            subtitle = String(format: Strings.subtitleFormat, completedToursCount, tours.count)
            progressView.progressTintColor = .primary
            checkmarkIcon.isHidden = true
        }

        subtitleLabel.text = subtitle

        // VoiceOver: Adding a period after the title to create a pause between the title and the subtitle
        accessibilityLabel = "\(title). \(subtitle)"

        let progress = Float(completedToursCount) / Float(tours.count)
        progressView.setProgress(progress, animated: false)
    }

    private func startObservingQuickStart() {
        NotificationCenter.default.addObserver(forName: .QuickStartTourElementChangedNotification, object: nil, queue: nil) { [weak self] notification in

            guard let userInfo = notification.userInfo,
                let element = userInfo[QuickStartTourGuide.notificationElementKey] as? QuickStartTourElement,
                element == .tourCompleted else {
                    return
            }

            self?.updateViews()
        }
    }

    private func stopObservingQuickStart() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func didTap() {
        onTap?()
    }
}

extension NewQuickStartChecklistView {

    private enum Metrics {
        static let mainStackViewInsets = UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 24).flippedForRightToLeft
        static let verticalStackViewWidthMultiplier = 3.0 / 5.0
        static let verticalStackViewSpacingPortrait = 12.0
        static let verticalStackViewSpacingLandscape = 16.0
        static let progressStackViewSpacing = 8.0
        static let progressViewHeight = 5.0
        static let imageWidth = 56.0
        static let imageHeight = 100.0
        static let checkmarkIconSize = CGSize(width: 16.0, height: 16.0)
    }

    private enum Colors {
        static let allTasksComplete = UIColor(light: .muriel(color: .jetpackGreen, .shade40), dark: .muriel(color: .jetpackGreen, .shade50))
        static let progressViewTrackTint = UIColor(light: .listBackground, dark: .systemGray3)
    }

    private enum Strings {
        static let subtitleFormat = NSLocalizedString("%1$d of %2$d completed",
                                                      comment: "Format string for displaying the number of completed quickstart tutorials. %1$d is the number completed, %2$d is the total number of tutorials available.")
        static let allTasksComplete = NSLocalizedString("All tasks complete!", comment: "Message shown when all Quick Start tasks are complete.")

    }
}
