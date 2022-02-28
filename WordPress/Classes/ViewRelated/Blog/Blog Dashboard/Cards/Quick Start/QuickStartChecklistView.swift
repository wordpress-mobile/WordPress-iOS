import UIKit
import WordPressShared

final class QuickStartChecklistView: UIView {

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
            trackColor: .listBackground
        )
        let view = ProgressIndicatorView(appearance: appearance)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
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
        startObservingQuickStart()
    }

    func configure(tours: [QuickStartTour], blog: Blog, title: String, hint: String) {
        self.tours = tours
        self.blog = blog
        titleLabel.text = title
        accessibilityHint = hint
        updateViews()
    }
}

extension QuickStartChecklistView {

    private func setupViews() {
        addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.mainStackViewVerticalPadding),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Metrics.mainStackViewVerticalPadding),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.mainStackViewHorizontalPadding),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.mainStackViewHorizontalPadding)
        ])

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
        } else {
            titleLabel.attributedText = NSAttributedString(string: title, attributes: [NSAttributedString.Key.strikethroughStyle: []])
        }

        subtitleLabel.text = String(format: Strings.subtitleFormat, completedToursCount, tours.count)

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
        static let mainStackViewSpacing = 16.0
        static let mainStackViewHorizontalPadding = 16.0
        static let mainStackViewVerticalPadding = 8.0
        static let labelStackViewSpacing = 4.0
        static let progressIndicatorViewSize = 24.0
    }

    private enum Strings {
        static let subtitleFormat = NSLocalizedString("%1$d of %2$d completed",
                                                      comment: "Format string for displaying number of completed quickstart tutorials. %1$d is number completed, %2$d is total number of tutorials available.")

    }
}
