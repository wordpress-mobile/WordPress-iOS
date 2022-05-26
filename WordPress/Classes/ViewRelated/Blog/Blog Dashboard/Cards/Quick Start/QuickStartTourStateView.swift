import UIKit

typealias QuickStartChecklistTappedTracker = (event: WPAnalyticsEvent, properties: [AnyHashable: Any])

final class QuickStartTourStateView: UIView {

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(blog: Blog, sourceController: UIViewController, checklistTappedTracker: QuickStartChecklistTappedTracker? = nil) {
        stackView.removeAllSubviews()
        let availableCollections = QuickStartFactory.collections(for: blog)
        for collection in availableCollections {
            var checklistView = collection.checklistViewType.init()
            checklistView.translatesAutoresizingMaskIntoConstraints = false
            checklistView.configure(collection: collection, blog: blog)
            checklistView.onTap = { [weak self] in
                self?.showQuickStart(with: collection, from: sourceController, for: blog, tracker: checklistTappedTracker)
            }
            stackView.addArrangedSubview(checklistView)
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

    private func showQuickStart(with collection: QuickStartToursCollection, from sourceController: UIViewController, for blog: Blog, tracker: QuickStartChecklistTappedTracker? = nil) {

        if let tracker = tracker {
            WPAnalytics.trackQuickStartEvent(tracker.event,
                                             properties: tracker.properties,
                                             blog: blog)
        }

        let checklist = QuickStartChecklistViewController(blog: blog, collection: collection)
        let navigationViewController = UINavigationController(rootViewController: checklist)
        sourceController.present(navigationViewController, animated: true)

        QuickStartTourGuide.shared.visited(.checklist)
    }
}
