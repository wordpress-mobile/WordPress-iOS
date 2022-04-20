import UIKit

typealias QuickStartChecklistTappedTracker = (event: WPAnalyticsEvent, properties: [AnyHashable: Any])

final class QuickStartTourStateView: UIView {

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            customizeChecklistView,
            growChecklistView
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var customizeChecklistView: QuickStartChecklistView = {
        let view = QuickStartChecklistView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var growChecklistView: QuickStartChecklistView = {
        let view = QuickStartChecklistView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(blog: Blog, sourceController: UIViewController, checklistTappedTracker: QuickStartChecklistTappedTracker? = nil) {

        customizeChecklistView.configure(
            tours: QuickStartTourGuide.customizeListTours(for: blog),
            blog: blog,
            title: Strings.customizeTitle,
            hint: Strings.customizeHint
        )

        customizeChecklistView.onTap = { [weak self] in
            self?.showQuickStart(with: .customize, from: sourceController, for: blog, tracker: checklistTappedTracker)
        }

        growChecklistView.configure(
            tours: QuickStartTourGuide.growListTours,
            blog: blog,
            title: Strings.growTitle,
            hint: Strings.growHint
        )

        growChecklistView.onTap = { [weak self] in
            self?.showQuickStart(with: .grow, from: sourceController, for: blog, tracker: checklistTappedTracker)
        }
    }

}

// MARK: - Setup

extension QuickStartTourStateView {

    private func setupViews() {
        addSubview(stackView)
        pinSubviewToAllEdges(stackView)
    }
}

// MARK: - Actions

extension QuickStartTourStateView {

    private func showQuickStart(with type: QuickStartType, from sourceController: UIViewController, for blog: Blog, tracker: QuickStartChecklistTappedTracker? = nil) {

        if let tracker = tracker {
            WPAnalytics.track(tracker.event,
                              properties: tracker.properties,
                              blog: blog)
        }

        let checklist = QuickStartChecklistViewController(blog: blog, type: type)
        let navigationViewController = UINavigationController(rootViewController: checklist)
        sourceController.present(navigationViewController, animated: true)

        QuickStartTourGuide.shared.visited(.checklist)
    }
}

// MARK: - Constants

extension QuickStartTourStateView {

    private enum Strings {
        static let customizeTitle = NSLocalizedString("Customize Your Site",
                                                      comment: "Name of the Quick Start list that guides users through a few tasks to customize their new website.")
        static let customizeHint = NSLocalizedString("A series of steps showing you how to add a theme, site icon and more.",
                                                     comment: "A VoiceOver hint to explain what the user gets when they select the 'Customize Your Site' button.")
        static let growTitle = NSLocalizedString("Grow Your Audience",
                                                comment: "Name of the Quick Start list that guides users through a few tasks to customize their new website.")
        static let growHint = NSLocalizedString("A series of steps to assist with growing your site's audience.",
                                                comment: "A VoiceOver hint to explain what the user gets when they select the 'Grow Your Audience' button.")
    }
}
