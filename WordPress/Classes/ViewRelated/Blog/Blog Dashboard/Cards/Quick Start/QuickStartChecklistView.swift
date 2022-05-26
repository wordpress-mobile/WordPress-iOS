import UIKit
import WordPressShared

// A view representing the progress on a Quick Start checklist. Built according to old design specs.
//
// This view is used to display multiple Quick Start tour collections per Quick Start card.
//
// This view can be deleted once we've fully migrated to using NewQuicksTartChecklistView.
// See QuickStartChecklistConfigurable for more details.
//
final class QuickStartChecklistView: UIView, QuickStartChecklistConfigurable {

    var tours: [QuickStartTour] = []
    var blog: Blog?
    var onTap: (() -> Void)?

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            labelStackView,
            progressIndicatorView
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = Metrics.mainStackViewSpacing
        return stackView
    }()

    private lazy var labelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = Metrics.labelStackViewSpacing
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.serifFontForTextStyle(.body, fontWeight: .semibold)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = Metrics.labelMinimumScaleFactor
        label.textColor = .text
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WPStyleGuide.fontForTextStyle(.callout)
        label.textColor = .textSubtle
        return label
    }()

    private lazy var progressIndicatorView: ProgressIndicatorView = {
        let appearance = ProgressIndicatorView.Appearance(
            size: Metrics.progressIndicatorViewSize,
            lineColor: .primary,
            trackColor: .separator
        )
        let view = ProgressIndicatorView(appearance: appearance)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.isAccessibilityElement = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        startObservingQuickStart()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    deinit {
        stopObservingQuickStart()
    }

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

extension QuickStartChecklistView {

    private func setupViews() {
        addSubview(mainStackView)
        pinSubviewToAllEdges(mainStackView, insets: Metrics.mainStackViewInsets)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }

    private func updateViews() {
        guard let blog = blog,
            let title = titleLabel.text else {
            return
        }

        let completedToursCount = QuickStartTourGuide.shared.countChecklistCompleted(in: tours, for: blog)

        if completedToursCount == tours.count {
            titleLabel.attributedText = NSAttributedString(string: title, attributes: [NSAttributedString.Key.strikethroughStyle: NSUnderlineStyle.single.rawValue])
            titleLabel.textColor = .textSubtle
        } else {
            titleLabel.attributedText = NSAttributedString(string: title, attributes: [:])
            titleLabel.textColor = .text
        }

        let subtitle = String(format: Strings.subtitleFormat, completedToursCount, tours.count)
        subtitleLabel.text = subtitle

        // VoiceOver: Adding a period after the title to create a pause between the title and the subtitle
        accessibilityLabel = "\(title). \(subtitle)"

        let progress = Double(completedToursCount) / Double(tours.count)
        progressIndicatorView.updateProgressLayer(with: progress)
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

extension QuickStartChecklistView {

    private enum Metrics {
        static let mainStackViewInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        static let mainStackViewSpacing = 16.0
        static let labelStackViewSpacing = 4.0
        static let progressIndicatorViewSize = 24.0
        static let labelMinimumScaleFactor = 0.5
    }

    private enum Strings {
        static let subtitleFormat = NSLocalizedString("%1$d of %2$d completed",
                                                      comment: "Format string for displaying number of completed quickstart tutorials. %1$d is number completed, %2$d is total number of tutorials available.")

    }
}
